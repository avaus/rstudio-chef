# Set up the package repository.
case node["platform"].downcase
when "ubuntu", "debian"
    include_recipe "apt"

    apt_repository "rstudio-cran" do
        uri node['rstudio']['apt']['uri']
        keyserver node['rstudio']['apt']['keyserver']
        key node['rstudio']['apt']['key']
        distribution "#{node['lsb']['codename']}/"
    end

    # package "r-base" do
    #     action :install
    # end

    package "libssl0.9.8" do
        action :install
    end

    # Not sure if needed...
    package "libapparmor1" do
        action :install
    end

    # Copied from https://github.com/davidski/rstudio-chef/blob/b9d51677823f73ee9251cd9b10aac569ec346883/recipes/server.rb
    Chef::Log.info('Retrieving RStudio Server file.')
    remote_rstudio_server_file = "#{node['rstudio']['server']['base_download_url']}/rstudio-server-#{node['rstudio']['server']['version']}-#{node['rstudio']['server']['arch']}.deb"
    local_rstudio_server_file = "#{Chef::Config[:file_cache_path]}/rstudio-server-#{node['rstudio']['server']['version']}-#{node['rstudio']['server']['arch']}.deb"
    remote_file local_rstudio_server_file do
        source remote_rstudio_server_file
        action :create_if_missing
        not_if { ::File.exists?('/etc/rstudio/rserver.conf') }
    end
    Chef::Log.info('Installing RStudio Server via dpkg.')
    execute "install-rstudio-server" do
        command "dpkg --install #{local_rstudio_server_file}"
        not_if { ::File.exists?('/etc/rstudio/rserver.conf') }
    end
    # dpkg_package "rstudio-server" do
    #     source local_rstudio_server_file
    #     action :install
    # end
when "redhat", "centos", "fedora"
    Chef::Application.fatal!("Redhat based platforms are not yet supported")
end

service "rstudio-server" do
    provider Chef::Provider::Service::Upstart
    supports :start => true, :stop => true, :restart => true
    action :start
end

template "/etc/rstudio/rserver.conf" do
    source "etc/rstudio/rserver.conf.erb"
    mode 0644
    owner "root"
    group "root"
    # Commented out, because this jammed the installation
#    notifies :restart, "service[rstudio-server]"
end

template "/etc/rstudio/rsession.conf" do
    source "etc/rstudio/rsession.conf.erb"
    mode 0644
    owner "root"
    group "root"
    # Commented out, because this jammed the installation
#    notifies :restart, "service[rstudio-server]"
end
