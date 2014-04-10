require 'find'
require 'bundler/setup'
require 'ipa_reader'
require 'fileutils'


debug = false

pdf_file_paths = []

app_dir = File.dirname(__FILE__) + '/../apps/'

Find.find(app_dir) do |path|
  pdf_file_paths << path if path =~ /.*\.ipa$/
end

infos = []
no_schemes = []
no_app_ids = []
bad_files = []
no_app_icons = []
no_iTunesArtworks = []
valid_ipas = []

pdf_file_paths.each do |file|
  begin
    ipa = IpaReader::IpaFile.new(file)

    url_schemes = ipa.url_schemes

    if url_schemes.count == 0
      no_schemes << file
    elsif ipa.app_id == ''
      no_app_ids << file
    else
      localized_names = ipa.localized_names
      name_cn = localized_names[:zh_CN]
      name_en = localized_names[:en]

      name_cn ||= localized_names[:'zh-Hans']
      name_cn ||= ipa.name
      name_en ||= ipa.name

      scheme = url_schemes[0]

      info = "name_cn: #{name_cn}, name_en: #{name_en}, app_id: #{ipa.app_id}, scheme: #{scheme}, icon_file: #{ipa.icon_file}, device_family: #{ipa.device_family}"
      puts info
      infos << info
      valid_ipas << ipa
    end
  rescue => e
    puts e
    puts file
    bad_files << file
  end
end

if !debug
  FileUtils.rm_rf("images")
  FileUtils.mkdir("images")
  valid_ipas.each do |ipa|
    if ipa.icon_file.to_s.length == 0
      no_app_icons << ipa.file_path
    else
      begin
        Zip::ZipFile.open(ipa.file_path) do |zip|
          File.open("images/AppIcon_#{ipa.app_id}.png", 'w') do |f|
            f.write zip.read(ipa.icon_file)
          end
          File.open("images/iTunesArtwork_#{ipa.app_id}.png", 'w') do |f|
            f.write zip.read('iTunesArtwork')
          end
        end
      rescue => e
        no_iTunesArtworks << ipa.file_path
      end
    end
  end

  File.open('log/infos.log', 'w') do |f|
    f.puts infos
  end

  File.open('log/no_schemes.log', 'w') do |f|
    f.puts no_schemes
  end

  File.open('log/no_app_ids.log', 'w') do |f|
    f.puts no_app_ids
  end

  File.open('log/bad_files.log', 'w') do |f|
    f.puts bad_files
  end

  File.open('log/no_app_icons.log', 'w') do |f|
    f.puts no_app_icons
  end

  File.open('log/no_iTunesArtworks.log', 'w') do |f|
    f.puts no_iTunesArtworks
  end
end


