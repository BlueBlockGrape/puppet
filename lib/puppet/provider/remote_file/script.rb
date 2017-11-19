require File.join(File.dirname(__FILE__), '..', 'remote_file')
require 'digest'

Puppet::Type.type(:remote_file).provide(:git, :parent => Puppet::Provider::RemoteFile) do
  desc "Downloads remote files"

  commands :curl => "/usr/bin/curl"

  def retrieve
    if !File.exists?(@resource[:path])
      return :absent
    end
    File.open(@resource[:path], 'r') do |file|
      sha1 = Digest::SHA1.new
      until file.eof?
        block = file.read(4096)
        sha1.update(block)
      end
      if sha1.hexdigest != @resource[:sha1hash]
        :absent
      else
        :present
      end
    end
  end

  def create
    execute([command(:curl), '--location', '--output', @resource[:path],
             '--silent', '--remote-time', @resource[:url]],
            { :failonfail => true, :uid => uid, :gid => gid })
    # Make sure the mode is correct
    should_mode = @resource.should(:mode)
    unless self.mode == should_mode
      self.mode = should_mode
    end
  end

  def destroy
    FileUtils.rm(@resource[:path])
  end

  def mode
    if !File.exists?(@resource[:path])
      return :absent
    end
    "%o" % (File.stat(@resource[:path]).mode & 0o7777)
  end

  def mode=(value)
    File.chmod(Integer("0o" + value), @resource[:path])
  end

  def uid
    Etc.getpwnam(@resource[:owner]).uid
  end

  def gid
    Etc.getgrnam(@resource[:group]).gid
  end
end

# vim: expandtab shiftwidth=2 tabstop=2
