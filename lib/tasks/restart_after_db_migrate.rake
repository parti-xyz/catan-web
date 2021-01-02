Rake::Task['db:migrate'].enhance do
  verbose(false) do
    mkdir_p 'tmp'
    touch 'tmp/restart.txt'
  end
end