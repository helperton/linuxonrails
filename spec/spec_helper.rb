require 'system_config'
require 'host_config'

$datadir = SYSTEM_CONFIG["data_dir"]

def clean_up
  print "Cleaning up testing work area..."
  system("rm -rf #{$datadir}")
  puts "done."
end

def setup_source(name)
  num = 9
  path = "rsync/testing/#{name}"
  # Create source dir
  1.upto(num) do |n|
    system("mkdir -p #{$datadir}/#{path}/pkg#{n}/files/#{n}")
    system("echo #{n} > #{$datadir}/#{path}/pkg#{n}/files/file#{n}")
    system("echo #{n} > #{$datadir}/#{path}/pkg#{n}/files/#{n}/file#{n}")
  end
  # Rsync all sources to source_nochanges before we run test
  sources = Array.new
  1.upto(num) do |n|
    sources.push("#{$datadir}/#{path}/pkg#{n}/files/")
  end
  # Create dest that won't have any changes
  system("rsync -a #{sources.join(" ")} #{$datadir}/rsync/testing/source_nochanges/")
  # Create dest that will have changes
  system("rsync -a #{sources.join(" ")} #{$datadir}/rsync/testing/source_changes/")
end
  
def setup_changes(name)
  path = "rsync/testing/#{name}"
  # Create destination, with modified, added, deleted stuff
  n = 10
  system("mkdir -p #{$datadir}/#{path}/#{n}")
  system("echo #{n} > #{$datadir}/#{path}/file#{n}")
  system("echo #{n} > #{$datadir}/#{path}/#{n}/file#{n}")

  # Modify some of our files, create new files, and delete some
  system("echo 1 > #{$datadir}/#{path}/2/file2")
  system("echo 2 > #{$datadir}/#{path}/3/file3")
  system("echo 'weeee' > #{$datadir}/#{path}/fileweeee")
  system("echo 'weeeehaw' > #{$datadir}/#{path}/7/fileweeehaw")
  system("chmod 777 #{$datadir}/#{path}/6/file6")
  system("chown 2 #{$datadir}/#{path}/5/file5")
  system("echo 1 > #{$datadir}/#{path}/excluded_file")
  system("echo 1 > #{$datadir}/#{path}/3/excluded_file")
  system("echo 1 > '#{$datadir}/#{path}/3/excluded_file with space in name'")
  system("mkdir '#{$datadir}/#{path}/12'")
  system("echo 1 > '#{$datadir}/#{path}/12/excluded_file_12_because_of_directory'")
  system("rm #{$datadir}/#{path}/4/file4")
  system("rm -rf #{$datadir}/#{path}/9")
end

def setup_ordering(name)
  num = 9
  path = "rsync/testing/#{name}"
  # Create source dir
  1.upto(num) do |n|
    system("mkdir -p #{$datadir}/#{path}/pkg#{n}/files/#{n}")
    system("echo #{n} > #{$datadir}/#{path}/pkg#{n}/files/file#{n}")
    system("echo #{n} > #{$datadir}/#{path}/pkg#{n}/files/#{n}/file#{n}")
  end
  system("echo 'win' > #{$datadir}/#{path}/pkg2/files/file_contains_win")
  system("echo 'lose' > #{$datadir}/#{path}/pkg3/files/file_contains_win")
  system("echo 'lose' > #{$datadir}/#{path}/pkg4/files/file_contains_win")
  system("echo 'lose' > #{$datadir}/#{path}/pkg5/files/file_contains_win")
end

def setup_testhost(hostname)
  h = HostConfig.new(hostname)
end

def setup_test_env
  print "Setting up new testing work area..."
  setup_source("source")
  setup_ordering("source_ordering")
  setup_testhost("hostname.domain.tld")
  # Sleep for 1.1 seconds ensures that the modify timestamp on the stuff which gets changed by 'setup_changes'
  # will be at least 1.1 seconds different than the source otherwise, rsync may not count it as being different
  # because of the 'quick check' we do by default with rsync.
  sleep 1.1
  setup_changes("source_changes")
  puts "done."
end

clean_up
setup_test_env
