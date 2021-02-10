val_syslog_pkg = attribute('syslog_pkg', value: 'rsyslog', description: 'syslog package to ensure present (default: rsyslog, alternative: syslog-ng...')
container_execution = begin
                        virtualization.role == 'guest' && virtualization.system =~ /^(lxc|docker)$/
                      rescue NoMethodError
                        false
                      end

control 'package-01' do
  impact 1.0
  title 'Install syslog server package'
  desc 'Syslog server is required to receive system and applications logs'
  # Fedora doesn't install with a syslogger out of the box and instead uses
  # systemd journal; as there is there is no affinity towards either rsyslog
  # or syslog-ng, we'll skip this check on Fedora hosts.
  only_if { os.name != 'fedora' && !container_execution }
  describe package(val_syslog_pkg) do
    it { should be_installed }
  end
end