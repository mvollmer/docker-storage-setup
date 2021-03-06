# Test DEVS= directive. Returns 0 on success and 1 on failure.
test_devs() {
  local devs=$DEVS
  local test_status
  local testname=`basename "$0"`
  local vg_name
  local vg_name="dss-test-foo"

 # Error out if any pre-existing volume group vg named dss-test-foo
  for vg in $(vgs --noheadings -o vg_name); do
    if [ "$vg" == "$vg_name" ]; then
      echo "ERROR: $testname: Volume group $vg_name already exists."
      return 1
    fi
  done

  # Create config file
  clean_config_files
  cat << EOF > /etc/sysconfig/docker-storage-setup
DEVS="$devs"
VG=$vg_name
EOF

 # Run docker-storage-setup
 $DSSBIN >> $LOGS 2>&1

 # Test failed.
 [ $? -ne 0 ] && return 1

 test_status=1
 # Make sure volume group $VG got created.
  for vg in $(vgs --noheadings -o vg_name); do
    if [ "$vg" == "$vg_name" ]; then
      test_status=0
      break
    fi
  done

 # Do cleanup only in case of success
 [ $test_status -eq 1 ] && return 1

  vgremove -y $vg_name >> $LOGS 2>&1
  remove_pvs "$devs"
  remove_partitions "$devs"
  clean_config_files
  return $test_status
}

test_devs
