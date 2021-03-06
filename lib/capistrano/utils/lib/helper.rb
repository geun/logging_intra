require 'colorize'
require 'erb'
require 'pathname'
require 'pp'

module Dove
  module Utils

    module Colorize
      # color output
      def cap_info message
        puts " INFO #{message}".colorize(:cyan)
      end

      def cap_warn message
        puts " WARN #{message}".colorize(:yellow)
      end

      def cap_error message
        puts " ERROR #{message}".colorize(:red)
      end
    end

    module Template
      def smart_template(from, to)
        #full_to_path = "#{shared_path}/config/#{to}"
        if from_erb_path = template_file(from)
          from_erb = StringIO.new(ERB.new(File.read(from_erb_path)).result(binding))
          upload! from_erb, to
          cap_info "copying: #{from_erb} to: #{to}"
        else
          cap_error "error #{from} not found"
        end
      end

      def template_file(name)
        if File.exist?((file = "config/deploy/#{fetch(:full_app_name)}/#{name}"))
          return file
        elsif File.exist?((file = "config/deploy/templates/#{name}"))
          return file
        end
        return nil
      end



      def local_copy_template(app, filename, force = false)
        config_dir = Pathname.new('config')
        target_path = config_dir.join('deploy/templates')

        unless Dir.exist?(target_path)
          mkdir_p target_path
          cap_info "create tempates folder"
        end

        template_path = File.expand_path("../../../#{app}/templates/#{filename}", __FILE__)

        cap_info "copy #{filename} to #{target_path} #{if force then 'with force' else '' end}"

        if File.exist?("#{target_path}/#{filename}") && !force
          cap_error "#{filename} is already exist, please check the command"
          return
        end

        FileUtils.cp(template_path, target_path)

        #unless test("[ -e #{target_path} ]")
        #  execute :mkdir, "#{root}/config/deploy/templates/"
        #end
        #execute :cp, "#{template_path}/#{name}", target_path
      end

      # Renders a template
      def render_template(template, output, scope)
        tmpl = File.read(template)
        erb = ERB.new(tmpl, 0, "<>")
        File.open(output, 'w') do |f|
          f.puts erb.result(scope)
        end
      end

      def move(source, destination)
        execute :sudo, "mv #{source} #{destination}"
      end

      # Upload and Move
      def upload_and_move source, destination
        cap_info "copying: #{source} to: #{destination} : #{File.exists?(source)}"
        if File.exists?(source)
          file = File.basename(source)
          upload! source, "/tmp/#{file}"
          move("/tmp/#{file}", destination)
          cap_info "copying: #{source} to: #{destination}"
          #sudo "mv ./#{file} #{destination}"
        end
      end
    end
  end
end

include Dove::Utils::Template
include Dove::Utils::Colorize

