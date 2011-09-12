=begin
  This recipe is designed to setup a fairly generic python einiroment. Adding
  the system packages that are required, installing pip and setting up 
  everything required to then add virtualenvs.
=end

%w{python-setuptools python-dev}.each do |pkg|
  package pkg do
    action :install
  end
end

execute "easy-install-pip" do
    command "easy_install pip"
end

execute "mkdir-pip-cache" do
  command "sudo mkdir -p /home/vagrant/.pip/cache/"
end

cookbook_file "/home/vagrant/.pip/pip.conf" do
  source "pip.conf"
  mode 0640
  owner "vagrant"
  group "vagrant"
  action :create_if_missing
end

["virtualenv", "virtualenvwrapper"].each do |pkg|

    execute "pip-install-#{pkg}" do
        command "pip install #{pkg}"
    end

end

if node.has_key?("python_global_packages")
  node[:python_global_packages].each do |pkg|
    execute "pip-global-install-#{pkg}" do
      command "pip install #{pkg}"
    end
  end
end

# This is a bit of a hack. At the moment it is creating the virtualenv as root
# since creating as the custom user doesn't seem to be working.
script "setup-virtualenv" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code "
  mkdir -p /home/vagrant/.virtualenvs
  export WORKON_HOME=/home/vagrant/.virtualenvs
  source /usr/local/bin/virtualenvwrapper.sh
  
  if [[ $(lsvirtualenv) != *#{node[:project_name]}* ]]
  then
    mkvirtualenv #{node[:project_name]}
  fi
  "
end

cookbook_file "/home/vagrant/.virtualenvs/postactivate" do
  source "postactivate"
  mode 0640
  owner "vagrant"
  group "vagrant"
  action :create
end

if node.has_key?("python_packages")
  node[:python_packages].each do |pkg|
    execute "pip-install-#{pkg}" do
      command "/home/vagrant/.virtualenvs/#{node[:project_name]}/bin/pip install #{pkg}"
    end
  end
end

# finally we change everything to the vagrant user
execute "chown-home" do
  command "sudo chown -R vagrant /home/vagrant"
end

