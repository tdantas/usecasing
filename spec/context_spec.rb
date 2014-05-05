require 'spec_helper'

describe UseCase::Context do 


  it 'receives a hash and generate setters from key' do 
    hash = {name: 'thiago', last: 'dantas', github: 'tdantas'}
    context = described_class.new(hash)
    expect(context.name).to eql(hash[:name])
    expect(context.last).to eql(hash[:last])
    expect(context.github).to eql(hash[:github])
  end

  it 'initializes without parameters' do 
    expect(described_class.new).to be_an(described_class)
  end

  it 'raises exception when argument is not a hash' do 
    expect {described_class.new(Object.new)}.to raise_error(ArgumentError)
  end

  it 'assign new values' do 
    context = described_class.new
    context.dog_name = 'mali'
    context.country = 'lisbon'
    context.age = 1

    expect(context.dog_name).to eql('mali')
    expect(context.country).to eql('lisbon')
    expect(context.age).to eql(1)
  end

  it 'handle hash with indifference' do 
    hash = { "name" => 'thiago', last: 'dantas'}
    context = described_class.new(hash)
    expect(context.name).to eql('thiago')
    expect(context.last).to eql('dantas')
  end

  it 'is success when there is no error' do 
    context = described_class.new({})
    expect(context.success?).to eql(true)
  end

  it 'adds error messages to errors' do 
    context = described_class.new({})
    context.failure(:email, 'email already exist')
    expect(context.errors[:email]).to eql(['email already exist'])
  end

  it 'fails when exist errors' do
    context = described_class.new({})
    context.failure(:email, 'email already exist')
    expect(context.success?).to eql(false)
  end

  it 'returns all messages indexed by key' do 
    context = described_class.new({})
    context.failure(:email, 'first')
    context.failure(:email, 'second')
    expect(context.errors[:email]).to include('first')
    expect(context.errors[:email]).to include('second')
    expect(context.errors[:email].join(",")).to eql("first,second")
  end

  it 'returns all messages indexed by key' do 
    context = described_class.new({})
    context.failure(:email, 'email')
    context.failure(:base,  'base')
    expect(context.errors.all("<br>")).to eql('email<br>base')
  end

   it 'returns all iterate over messages' do 
    context = described_class.new({})
    context.failure(:email, 'email')
    context.failure(:base,  'base')
    @expected = ""
    context.errors.all { |message| @expected.concat"<li>#{message}</li>" } 
    expect(@expected).to eql('<li>email</li><li>base</li>')
  end

  it 'returns a hash' do 
    context = described_class.new({})
    context.name = 'thiago'
    context.last_name = 'dantas'
    expect(context.to_hash).to eql({ name: 'thiago' , last_name: 'dantas'})
  end

  it "iterates successfully over errors" do
    context = described_class.new({})
    context.failure(:error_1, "this is the first error")
    context.failure(:error_2, "this is a second error")

    errors_keys = [];
    errors_values = [];
    context.errors.each  do |k, v| 
      errors_keys << k
      errors_values << v;
    end

    expect(errors_keys).to eql([:error_1, :error_2])
    expect(errors_values).to eql([["this is the first error"], ["this is a second error"]])
  end

  # https://github.com/tdantas/usecasing/issues/4
  it "does not mark failure when access key that does not exist" do 
    ctx = described_class.new
    expect(ctx.success?).to be_true
    ctx[:key]
    expect(ctx.success?).to be_true
  end

end

