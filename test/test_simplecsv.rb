# $Id$
# Copyright:: (C) 2007 TOMITA Masahiro <tommy@tmtm.org>

require "test/unit"
require "simplecsv"
require "tempfile"

class TC_SimpleCSV < Test::Unit::TestCase
  def setup()
    @tmpf = Tempfile.new("test")
    @tmpf.puts <<EOS
a,b,c
0,1,2
EOS
    @tmpf.flush
    @tmpf.rewind
  end
  def teardown()
    @tmpf.close!
  end

  def test_foreach()
    expect = [["a","b","c"],["0","1","2"]]
    SimpleCSV.foreach(@tmpf.path) do |r|
      assert_equal(expect.shift, r)
    end
    assert(expect.empty?)
  end

  def test_readlines()
    expect = [["a","b","c"],["0","1","2"]]
    assert_equal(expect, SimpleCSV.readlines(@tmpf.path))
  end

  def test_parse()
    expect = [["a","b","c"],["0","1","2"]]
    assert_equal(expect, SimpleCSV.parse("a,b,c\n0,1,2"))
  end

  def test_open()
    assert_kind_of(SimpleCSV, SimpleCSV.open(@tmpf.path))
  end

  def test_open_block()
    ret = SimpleCSV.open(@tmpf.path) do |csv|
      assert_kind_of(SimpleCSV, csv)
      12345
    end
    assert_equal(12345, ret)
  end

  def test_initialize()
    assert_kind_of(SimpleCSV, SimpleCSV.new(@tmpf))
    assert_kind_of(SimpleCSV, SimpleCSV.new("a,b,c"))
  end

  def test_close()
    SimpleCSV.new(@tmpf).close
    assert(@tmpf.closed?)
  end

  def test_shift()
    csv = SimpleCSV.new(<<EOS)
a,b,c
1,2,3
EOS
    assert_equal(["a","b","c"], csv.shift)
    assert_equal(["1","2","3"], csv.shift)
    assert_equal(nil, csv.shift)
  end

  def test_shift_crlf()
    csv = SimpleCSV.new(<<EOS)
a,b,c\r
1,2,3\r
EOS
    assert_equal(["a","b","c"], csv.shift)
    assert_equal(["1","2","3"], csv.shift)
    assert_equal(nil, csv.shift)
  end

  def test_shift_cr()
    csv = SimpleCSV.new("a,b,c\r1,2,3\r")
    assert_equal(["a","b","c"], csv.shift)
    assert_equal(["1","2","3"], csv.shift)
    assert_equal(nil, csv.shift)
  end

  def test_shift_quote()
    csv = SimpleCSV.new(<<EOS)
"a","b","c"
"1","2","3"
EOS
    assert_equal(["a","b","c"], csv.shift)
    assert_equal(["1","2","3"], csv.shift)
    assert_equal(nil, csv.shift)
  end

  def test_shift_quote_in_quote()
    csv = SimpleCSV.new(<<EOS)
"a","""","c"
"1","2""3","4"
EOS
    assert_equal(["a","\"","c"], csv.shift)
    assert_equal(["1","2\"3", "4"], csv.shift)
    assert_equal(nil, csv.shift)
  end

  def test_shift_invalid_dq()
    csv = SimpleCSV.new(<<EOS)
"a","b","c"
"1",2","3"
EOS
    assert_equal(["a","b","c"], csv.shift)
    assert_raises(SimpleCSV::MalformedCSVError){csv.shift}
  end

  def test_shift_lf_in_data()
    csv = SimpleCSV.new(<<EOS)
"a","b","c
1","2","3"
EOS
    assert_equal(["a","b","c\n1","2","3"], csv.shift)
  end

  def test_shift_empty_line()
    csv = SimpleCSV.new(<<EOS)
a,b,c

1,2,3
EOS
    assert_equal(["a","b","c"], csv.shift)
    assert_equal([], csv.shift)
    assert_equal(["1","2","3"], csv.shift)
  end

  def test_shift_empty()
    csv = SimpleCSV.new("")
    assert_equal(nil, csv.shift)
  end
end
