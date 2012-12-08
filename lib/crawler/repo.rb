# -- coding: utf-8

class Crawler
  class Repo
    def initialize(url_or_dir)
      if url_or_dir[Crawler::REPO_DIR]
        @dir = url_or_dir
      else
        @url = url_or_dir
      end
    end

    def self.known_repos
      `find #{Crawler::REPO_DIR} -name .git -type d`.lines.map do |gitdir|
        new(File.dirname(gitdir))
      end
    end

    def dir
      @dir ||= begin
        uri = URI.parse(@url)
        File.join(REPO_DIR, uri.path[1], uri.path)
      end
    end

    def url
      @url ||= begin
        `git --git-dir #{git_dir} remote -v`.lines.first[/http.*? /].strip
      end
    end

    def git_dir
      File.join(dir, ".git")
    end

    def clone
      system({"GIT_ASKPASS" => "/bin/false"}, *%W!git clone --depth 1 #{url} #{dir}!) unless File.directory?(dir)
    end

    def fetch
      clone
      unless system({"GIT_ASKPASS" => "/bin/false"}, *%W!git --git-dir #{git_dir} pull -f origin master!)
        puts dir
      end
    end

    def detect_plugins
      @plugins ||= `find #{dir} -type f -name '*vimrc' -print0 -o -type f -name '*.vim' -print0 | xargs -0 grep -E 'NeoBundle|Bundle'`.lines.map do |line|
        match = line.match(/^(.*?):\s*(?:Neo)?Bundle(?:Lazy)? ["'](.*?)["']/)
        next unless match
        symbol = match[2]
        filename = match[1].gsub(dir, "")
        config_url = "#{url}/blob/master#{filename}"
        next if config_url["vundle/test/vimrc"]
        next if config_url["neobundle.vim/test/vimrc"]
        next if config_url["neobundle/test/vimrc"]
        repourl = case symbol
        when /^github:(.*)/, /@github.com:(.*)/ # => github:user/repo
          "https://github.com/#{Regexp.last_match[1]}"
        when /^http/, /^git/ # full repo url
          symbol.gsub(%r"git://(github.com)", "https://\\1")
        when %r!^[^/]+/([^/]+)$! # username/repo => github
          "https://github.com/#{symbol}"
        when "", nil, ","
          next
        else # => vim.org
          "https://github.com/vim-scripts/#{symbol}"
        end
        {
          :plugin => {
            :repo => repourl,
            :name => friendly_name(repourl),
            :author => repourl[%r!github\.com/(.*?)/!, 1],
          },
          :config => {
            :url => config_url,
            :author => File.basename(File.dirname(dir)),
          },
        }
      end.compact
    end

    def friendly_name(plugin_url)
      begin
        File.basename(URI.parse(plugin_url).path).gsub(/\.git$/, "")
      rescue URI::InvalidURIError
        puts plugin_url # should fix
      end
    end
  end
end
