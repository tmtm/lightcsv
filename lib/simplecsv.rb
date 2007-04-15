# = SimpleCSV
# CSV parser
#
# $Id$
# Copyright:: 2007 (C) TOMITA Masahiro <tommy@tmtm.org>
# License:: Ruby's
# Homepage:: http://tmtm.org/ja/ruby/simplecsv

require "strscan"

# == CSV のパース
# 各レコードはカラムを要素とする配列である。
# レコードの区切りは LF,CR,CRLF のいずれか。
#
# 以下が csv.rb と異なる。
# * 空行は [nil] ではなく [] になる。
# * 「"」で括られていない空カラムは nil ではなく "" になる。
#
# == 例
# * CSVファイルのレコード毎にブロックを繰り返す。
#     SimpleCSV.foreach(filename){|row| ...}
#   次と同じ。
#     SimpleCSV.open(filename){|csv| csv.each{|row| ...}}
#
# * CSVファイルの全レコードを返す。
#     SimpleCSV.readlines(filename)  # => [[col1,col2,...],...]
#   次と同じ。
#     SimpleCSV.open(filename){|csv| csv.map}
#
# * CSV文字列のレコード毎にブロックを繰り返す。
#     SimpleCSV.parse("a1,a2,..."){|row| ...}
#   次と同じ。
#     SimpleCSV.new("a1,a2,...").each{|row| ...}
#
# * CSV文字列の全レコードを返す。
#     SimpleCSV.parse("a1,a2,...")  # => [[a1,a2,...],...]
#   次と同じ。
#     SimpleCSV.new("a1,a2,...").map
#
class SimpleCSV
  include Enumerable

  # == パースできない形式の場合に発生する例外
  # MalformedCSVError#message は処理できなかった位置から 10バイト文の文字列を返す。
  class MalformedCSVError < RuntimeError; end

  # ファイルから一度に読み込むバイト数
  BUFSIZE = 64*1024

  # ファイルの各レコード毎にブロックを繰り返す。
  # ブロック引数はレコードを表す配列。
  def self.foreach(filename, &block)
    self.open(filename) do |f|
      f.each(&block)
    end
  end

  # ファイルの全レコードをレコードの配列で返す。
  def self.readlines(filename)
    self.open(filename) do |f|
      return f.map
    end
  end

  # CSV文字列の全レコードをレコードの配列で返す。
  # ブロックが与えられた場合は、レコード毎にブロックを繰り返す。
  # ブロック引数はレコードを表す配列。
  def self.parse(string, &block)
    unless block
      return self.new(string).map
    end
    self.new(string).each do |row|
      block.call row
    end
    return nil
  end

  # ファイルをオープンして SimpleCSV オブジェクトを返す。
  # ブロックを与えた場合は SimpleCSV オブジェクトを引数としてブロックを実行する。
  def self.open(filename, &block)
    f = File.open(filename)
    csv = self.new(f)
    if block then
      begin
        return block.call(csv)
      ensure
        csv.close
      end
    else
      return csv
    end
  end

  # SimpleCSV オブジェクトを生成する。
  # _src_ は String か IO。
  def initialize(src)
    if src.kind_of? String then
      @file = nil
      @ss = StringScanner.new(src)
    else
      @file = src
      @ss = StringScanner.new("")
    end
    @buf = ""
  end

  # SimpleCSV オブジェクトに関連したファイルをクローズする。
  def close()
    @file.close if @file
  end

  # 1レコードを返す。データの最後の場合は nil を返す。
  # 空行の場合は空配列([])を返す。
  # 空カラムは「"」で括られているか否かにかかわらず空文字列("")になる。
  def shift()
    cols = []
    while true
      read_next_data if @ss.rest_size < 2
      break if @ss.eos?

      if @ss.match?(/\"/)
        unless @ss.scan(/\"((?:\"\"|[^\"])*)\"/n)
          read_next_data or raise MalformedCSVError, @ss.rest[0,10]
          next
        end
        cols << @ss[1].gsub(/\"\"/, '"')
        read_next_data if @ss.rest_size < 2
      else
        col = @ss.scan(/[^\",\r\n]*/n)
        if @ss.rest_size < 2
          @ss.unscan
          unless read_next_data
            @ss.terminate
            cols << col
            break
          end
          next
        end
        cols << col
      end
      next if @ss.scan(/,/)
      @ss.scan(/\r?\n|\r|\z/n) or raise MalformedCSVError, @ss.rest[0,10]
      break
    end
    return nil if cols.empty?
    return [] if cols.size == 1 and cols[0].empty?
    return cols
  end

  # 各レコード毎にブロックを繰り返す。
  def each()
    while row = shift
      yield row
    end
  end

  # 現在位置以降のレコードの配列を返す。
  def readlines()
    return map
  end

  private

  def read_next_data()
    return nil unless @file
    r = @file.read(BUFSIZE, @buf)
    @ss = StringScanner.new(@ss.rest + @buf) if r
    return r
  end
end
