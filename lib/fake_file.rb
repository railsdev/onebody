class FakeFile < StringIO
  include Paperclip::Upfile

  def initialize(data, filename)
    super(data)
    @filename = filename
  end

  def original_filename
    @filename
  end

  def path
    @filename
  end

  def size
    self.length
  end
end
