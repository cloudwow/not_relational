require 'rubygems'
require 'rake'
$: << "." 

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "not_relational"
    gem.summary = "I am not relational."
    gem.email = "david@cloudwow.com"
    gem.homepage = "http://github.com/cloudwow/not_relational"
    gem.authors = ["cloudwow"]
    gem.files=[".document",
               ".gitignore",
               "LICENSE",
               "README.rdoc",
               "Rakefile",
               "VERSION",
               "lib/not_relational.rb",
               "lib/not_relational/*"
              ]
    gem.add_dependency( "aws-sdb")

    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = 'not_relational'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = false
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/*_test.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end


task :default => :test


namespace :metrics do
  def get_mtime(path)
    File.mtime(path).strftime("%Y-%m-%d %I:%M %p")
  end
  
  desc 'Generates Reek report'
  task :make_reek do
    require 'find'
    require 'fileutils'
    reek_dir_name = "reek"
    reek_dir = "./metrics/#{reek_dir_name}"
    index_file = "#{reek_dir}/index.html"
    output_files = {}
    
    unless File.exists?(reek_dir) && File.directory?(reek_dir)
      FileUtils.mkdir(reek_dir)
    end
    
    Find.find('./lib') do |path|
      if (
          path =~ /\.rb$/i
          )
        output_file = "#{File.basename(path)}.txt"
        cmd = "reek #{path} > #{reek_dir}/#{output_file}"
        puts cmd
        system(cmd)
        output_files[path] = output_file
      end
    end
    
    puts "Writing index file to #{index_file}..."
    paths = output_files.keys.sort
    
    File.open(index_file, 'w') do |file|
      file.write('<html>')
      file.write('<head>')
      file.write("<title>Reek Results for ./lib</title>")
      file.write('</head>')
      file.write('<body>')
      file.write("<h1>Reek Results for ./lib</h1>")
      file.write('<ol>')

      paths.each do |path|
        name = output_files[path]
        file.write('<li>')
        link_name = File.basename(name, '.rb.txt')
        file.write('<a href="' + name + '">' + link_name + '</a>')
        file.write(' from ' + path)
        file.write("</li>\n")
      end

      file.write('</ol>')
      file.write('</body>')
      file.write('</html>')
    end
  end

  desc 'Generates public/reports.html'
  task :make_index do
    require 'find'
    require 'fileutils'
    puts "\nGenerating index of reports..."
    reports = []
    index_file = "./metrics/reports.html"
    
    Find.find('./lib') do |path|
      if (
          path =~ /flay_report\.txt$/ ||
          path =~ /flog_report\.txt$/ ||
          path =~ /roodi_report\.txt$/
          )
        reports << File.basename(path)
      end
    end
    
    File.open(index_file, 'w') do |file|
      file.write('<html>')
      file.write('<head>')
      file.write("<title>Reports for ./lib</title>")
      file.write('</head>')
      file.write('<body>')
      file.write("<h1>Reports for ./lib</h1>")
      file.write('<ol>')

      reek_file = "./metrics/reek/index.html"
      if File.exists?(reek_file)
        file.write('<li><a href="reek/index.html">Reek</a>')
        file.write(", last updated #{get_mtime(reek_file)}</li>")
      end

      token_file = "./metrics/saikuro/index_token.html"
      if File.exists?(token_file)
        file.write('<li><a href="saikuro/index_token.html">Tokens</a>')
        file.write(", last updated #{get_mtime(token_file)}</li>")
      end

      cyclo_file = "./metrics/saikuro/index_cyclo.html"
      if File.exists?(cyclo_file)
        file.write('<li><a href="saikuro/index_cyclo.html">Cyclomatic complexity</a>')
        file.write(", last updated #{get_mtime(cyclo_file)}</li>")
      end

      reports.each do |name|
        file.write('<li>')
        file.write('<a href="' + name + '">' + name + '</a>')
        file.write(", last updated #{get_mtime('./lib/' + name)}")
        file.write('</li>')
      end

      file.write('</ol>')
      file.write('</body>')
      file.write('</html>')
    end
  end

  desc 'Generates Roodi report'
  task :make_roodi do 
    puts "\nGenerating Roodi report..."
    cmd = "roodi \"./lib/**/*.rb\" > ./metrics/roodi_report.txt"
    puts cmd
    system(cmd)
  end

  desc 'Generates Flay report'
  task :make_flay do
    puts "\nGenerating Flay report..."
    cmd = "flay ./lib > ./metrics/flay_report.txt"
    puts cmd
    system(cmd)
  end

  desc 'Generates Saikuro report'
  task :make_saikuro do
    saikuro_dir = "./metrics/saikuro/"
    unless File.exists?(saikuro_dir) && File.directory?(saikuro_dir)
      FileUtils.mkdir(saikuro_dir)
    end
    
    puts "\nGenerating Saikuro report..."
    cmd = "saikuro -c -t -i ./lib -y 0 -w 11 -e 16 -o #{saikuro_dir}"
    puts cmd
    system(cmd)
  end

  desc 'Generates Flog report'
  task :make_flog do
    puts "\nGenerating Flog report..."
    cmd = "flog ./lib > ./metrics/flog_report.txt"
    puts cmd
    system(cmd)
  end

  desc 'Generates all reports.'
  task :make_all do
    system('rake metrics:make_reek')
    system('rake metrics:make_roodi')
    system('rake metrics:make_flay')
    system('rake metrics:make_saikuro')
    system('rake metrics:make_flog')
    system('rake metrics:make_index')
  end
end
task :tags  do
  files = FileList['**/*.rb'].exclude("vendor")

  puts "Making Emacs TAGS file"


  sh "ctags -e #{files}", :verbose => false

end


