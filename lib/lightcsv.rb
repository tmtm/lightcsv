# coding: us-ascii
# = LightCsv
# CSV parser
#
# Copyright:: 2007 (C) TOMITA Masahiro <tommy@tmtm.org>
# License:: Ruby's
# Homepage:: http://tmtm.org/ja/ruby/lightcsv

require "strscan"

# CSV parser
class LightCsv
  include Enumerable

  class InvalidFormat < RuntimeError; end

  # @param [String] filename Filename
  # @yield [row]
  # @yieldparam [Array<String>] row One record
  # @return [void]
  def self.foreach(filename, &block)
    self.open(filename) do |f|
      f.each(&block)
    end
  end

  # @param [String] filename Filename
  # @return [Array<Array<String>>] All records.
  def self.readlines(filename)
    self.open(filename) do |f|
      return f.entries
    end
  end

  # @param [String] string CSV string
  # @yield [row]
  # @yieldparam [Array<String>] row One record
  # @return [Array<Array<String>>] if block is unspecified
  # @return [nil] if block is specified
  def self.parse(string, &block)
    unless block
      return self.new(string).entries
    end
    self.new(string).each do |row|
      block.call row
    end
    return nil
  end

  # @param [String] filename Filename
  # @yield [csv]
  # @yieldparam [LightCsv] csv LightCsv object
  # @return [LightCsv] if block is unspecified
  # @return [Object] block value if block is specified
  def self.open(filename, &block)
    f = File.open(filename)
    csv = self.new(f)
    if block
      begin
        return block.call(csv)
      ensure
        csv.close
      end
    else
      return csv
    end
  end

  # @param [String / IO] src CSV source
  def initialize(src)
    if src.kind_of? String
      @file = nil
      @ss = StringScanner.new(src)
    else
      @file = src
      @ss = StringScanner.new("")
    end
    @buf = ""
    @bufsize = 64*1024
  end
  attr_accessor :bufsize

  # close file
  # @return [void]
  def close
    @file.close if @file
  end

  # return one record.
  # @return [Array<String>] one record. empty array for empty line.
  # @return [nil] if end of data is reached.
  def shift
    return nil if @ss.eos? and ! read_next_data
    cols = []
    while true
      if @ss.eos? and ! read_next_data
        cols << ""
        break
      end
      if @ss.scan(/\"/)
        until @ss.scan(/((?:\"\"|[^\"])*)\"(,|\r\n|\n|\r|\z)/)
          read_next_data or raise InvalidFormat, @ss.rest[0,10]
        end
        cols << @ss[1].gsub(/\"\"/, '"')
      else
        unless @ss.scan(/([^\",\r\n]*)(,|\r\n|\n|\r|\z)/)
          raise InvalidFormat, @ss.rest[0,10]
        end
        cols << @ss[1]
      end
      break unless @ss[2] == ','
    end
    cols.clear if cols.size == 1 and cols.first.empty?
    cols
  end

  # iterator
  # @yield [row]
  # @yieldparam [Array<String>] row One record
  def each
    while row = shift
      yield row
    end
  end

  # Array of record
  # @return [Array<Array<String>>] records
  def readlines
    return entries
  end

  private

  # @return [nil] when EOF reached.
  def read_next_data
    return unless @file && @buf
    while buf = @file.read(@bufsize)
      @buf.concat buf
      if l = @buf.slice!(/\A.*(?:\r\n|\r(.)|\n)/m)
        if $1
          @buf[0,0] = $1
          l.chop!
        end
        @ss.string = @ss.rest + l
        return true
      end
    end
    return if @buf.empty?
    @ss.string = @ss.rest + @buf
    @buf = nil
    true
  end
end
