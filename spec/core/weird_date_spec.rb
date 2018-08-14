# this comes from DynamoDB
# where such weird thing is used as a key
# see "over_time" table

describe WeirdDate do
  describe '.from_date' do
    it 'converts 2017-01-01 to "17001" where 17 is year and 001 is day of year' do
      expect(WeirdDate.from_date('2017-01-01'.to_date)).to eql 17001
      expect(WeirdDate.from_date('2018-12-31'.to_date)).to eql 18365
      expect(WeirdDate.from_date('2019-03-29'.to_date)).to eql 19088
    end
  end

  describe '.to_date' do
    it 'converts "17001" back to date 2017-01-01' do
      expect(WeirdDate.to_date(17001)).to eql '2017-01-01'.to_date
      expect(WeirdDate.to_date(18365)).to eql '2018-12-31'.to_date
      expect(WeirdDate.to_date(19088)).to eql '2019-03-29'.to_date
    end
  end
end
