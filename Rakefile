namespace :deploy do
  task :restart_bot do
    system(File.expand_path(File.join(File.dirname(__FILE__), 'bin', 'bot_control')), 'stop')
    system(File.expand_path(File.join(File.dirname(__FILE__), 'bin', 'bot_control')), 'start')
  end

  task :post_deploy => [ :restart_bot ]
end
