require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"

before do
  @contents = File.readlines("data/toc.txt")
end

helpers do
  def slugify(text)
    text.downcase.gsub(/\s+/, "-").gsub(/[^\w-]/, "")
  end

  def in_paragraphs(text)
    text.split("\n\n").map.with_index do |paragraph, index|
      "<p id='paragraph#{index}'>#{paragraph}</p>"
    end.join
  end

  # Calls the block for each chapter, passing that chapter's number, name, and
  # text.
  def each_chapter
    @contents.each_with_index do |name, index|
      number = index + 1
      text = File.read("data/chp#{number}.txt")
      yield number, name, text
    end
  end

  # This method returns an Array of Hashes representing content that match the
  # specified query.
  def content_matching(query)
    results = []

    return results if !query || query.empty?

    each_chapter do |number, name, text|
      paragraphs = {}
      text.split("\n\n").each_with_index do |paragraph, paragraph_number|
        paragraphs[paragraph_number] = paragraph if paragraph.include?(query)
      end
      results << {number: number, name: name, paragraphs: paragraphs} if !paragraphs.empty?
    end
    results
  end

  def bold_matching(paragraph, query)
    paragraph.gsub(query, "<strong>#{query}</strong>")
  end
end

not_found do
  redirect "/"
end

get "/" do
  @title = "The Adventures of Sherlock Holmes"
  erb :home
end

get "/chapters/:number" do
  number = params[:number].to_i
  chapter_name = @contents[number - 1]

  redirect "/" unless (1..@contents.size).cover? number

  @title = "Chapter #{number}: #{chapter_name}"
  @chapter = File.read("data/chp#{number}.txt")

  erb :chapter
end

get "/search" do
  @results = content_matching(params[:query])
  p @results
  erb :search
end