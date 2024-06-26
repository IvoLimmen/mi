require "process"
require "xml"

projects = [] of String

def is_jar(file : String) : Bool
  !File.read(file).index("<packaging>jar</packaging>").nil?
end

def get_artifact_name(file : String) : String | Nil

  doc = XML.parse(File.read(file))
  project = doc.first_element_child
  if project
    project.children.select(&.element?).each do |child|
      if child.name == "artifactId"
        return child.content
      end
    end
  end
  nil
end

def change_files : Array(String)
  cmd = "git"
  args = ["status", "-s"]
  return_value = [] of String
  stdout = IO::Memory.new
  stderr = IO::Memory.new
  status = Process.run(cmd, args, shell: false, output: stdout, error: stderr)
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

# run
change_files().each do |s|
  found = search_pom_files(s)

  if !found.nil?
    file = get_artifact_name(found)
    if !file.nil?
      projects << file
    end
  end
end

total_set = [] of String

projects.each do |s|
  total_set << ":#{s}"
end

output = [] of String

# start with the mvn command
output << "mvn"

# add all passed arguments
ARGV.each do |s|
  output << s
end

# add the special pl argument with the projects that are changed
output << "-pl #{total_set.join(",")}"

puts output.join(" ")
