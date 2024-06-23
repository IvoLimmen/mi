require "process"

projects = [] of String

def is_jar(file : String) : Bool
  !File.read(file).index("<packaging>jar</packaging>").nil?
end

def change_files : Array(String)
  cmd = "git"
  args = ["status", "-s"]
  return_value = [] of String
  stdout = IO::Memory.new
  stderr = IO::Memory.new
  status = Process.run("git", args, shell: false, output: stdout, error: stderr)
  if status.success?
    stdout.to_s.split("\n").each do |s|
      if s.strip().index(' ') != nil
        parts = s.strip().split(" ")
        return_value << parts[1]
      end
    end
  end

  return_value
end

def search_pom_files(file : String) : String | Nil

  if File.exists?(file)
    if file.index("/src") != nil
      index = file.index("/src").not_nil!
      pom_file = file[0, index] + "/pom.xml"

      if File.exists?(pom_file) && is_jar(pom_file)
        pom_file
      end
    end
  end
end

def get_artifact_name(pom_file : String) : String

  puts pom_file

  while pom_file.count("/") > 1
    index = pom_file.index("/").not_nil!
    pom_file = pom_file[index + 1, pom_file.size]
  end

  puts pom_file

  ":" + pom_file[0..-9]
end

# run
change_files().each do |s|
  found = search_pom_files(s)

  if !found.nil?
    projects << get_artifact_name(found)
  end
end

total_set = projects.to_set.join(",")

puts "mvn clean install -pl #{total_set}"
