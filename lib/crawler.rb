# -- coding: utf-8

class Crawler
  REPO_DIR = File.expand_path("../../repos", __FILE__)

  def initialize
  end

  def explore(*words)
    hydra = Typhoeus::Hydra.new
    repos = []
    words = %W!vimrc dotfiles vimfiles neobundle vundle myvim! if words.empty?
    words.each do |q|
      3.times do |page|
        req = Typhoeus::Request.new("https://api.github.com/legacy/repos/search/#{q}?start_page=#{page}")
        req.on_complete do |res|
          return if res.code != 200
          info = MultiJson.load(res.body).fetch("repositories", [])
          info.each do |repo|
            next if repo["fork"]
            repos << Repo.new(URI.join("https://github.com/#{repo["owner"]}/#{repo["name"]}").to_s)
          end
        end
        hydra.queue req
      end
    end
    hydra.run
    repos.uniq
  end
end

require "lib/crawler/repo"
