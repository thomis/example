class Holiday < ApplicationRecord
  validates :name, :from, :to, presence: true
  validates :name, uniqueness: true

  belongs_to :creator, class_name: "Person", foreign_key: "creator_id"
  belongs_to :updator, class_name: "Person", foreign_key: "updator_id"

  after_initialize :defaults

  def defaults
    self.to ||= from # set same as from
  end

  def self.holiday?(a_date)
    a_date = a_date.to_date if a_date.is_a?(Time)
    all.each do |holiday|
      return true if holiday.from <= a_date && a_date <= holiday.to
    end
    false
  end

  def self.remove_old
    Holiday.where([ '"to" < ?', 7.days.ago ]).each do |holiday|
      AppLogger.info("Old holiday [#{holiday.name}] has been deleted")
      holiday.destroy
    end
  end

  def self.generate(year = Date.today.year)
    holidays = [
      # moving holidays
      [ "Gründonnerstag/Karfreitag", holy_thursday(year), good_friday(year) ],
      [ "Ostern/Ostermontag", easter(year), easter_monday(year) ],
      [ "Pfingsten/Pfingstmontag", whit_sunday(year), whit_monday(year) ],
      [ "Auffahrt/Freitag nach Auffahrt", ascension_day(year), ascension_day(year) + 1.day ],
      [ "Basler Fasnacht", morgenstraich(year), morgenstraich(year) + 2.days ],

      # fixed holidays
      [ "Tag der Arbeit", Date.new(year, 5, 1), Date.new(year, 5, 1) ],
      [ "Nationalfeiertag", Date.new(year, 8, 1), Date.new(year, 8, 1) ],
      [ "Heiliger Abend/Weihnachten/Stephanstag", Date.new(year, 12, 24), Date.new(year, 12, 26) ],
      [ "Silvester/Neujahr", Date.new(year, 12, 31), Date.new(year + 1, 1, 1) ]
    ]

    holidays.each do |name, from, to|
      next unless Date.today <= from

      if Holiday.find_by_name(name).nil?
        AppLogger.info("About to create #{name}...")
        Holiday.create!(
          name: name,
          from: from,
          to: to,
          creator_id: USER_SYSTEM,
          updator_id: USER_SYSTEM
        )
      else
        AppLogger.info("Holiday [#{name}] exists already")
      end
    end
  end

  def self.easter(year = 2016)
    # Wir benötigen zunächst zwei Konstanten, nämlich M = 24 und N = 5.
    # Diese Werte gelten noch bis und mit 2099, von 2100 bis 2199 ist dann M = 24 und N = 6.
    m, n = 24, 5 if year <= 2099
    m, n = 24, 6 if year >= 2100 && year <= 2199

    a = year % 19
    b = year % 4
    c = year % 7
    d = (19 * a + m) % 30
    e = (2 * b + 4 * c + 6 * d + n) % 7

    month = 3

    day = 22 + d + e

    if day > 31
      month = 4
      day = d + e - 9
    end

    Date.new(year, month, day)
  end

  def self.easter_monday(year = 2016)
    easter(year) + 1
  end

  # Pfingsten
  def self.whit_sunday(year = 2016)
    easter(year) + 49
  end

  def self.whit_monday(year = 2016)
    easter(year) + 50
  end

  # Auffahrt
  def self.ascension_day(year = 2016)
    easter(year) + 39
  end

  # Gruendonnerstag
  def self.holy_thursday(year = 2016)
    easter(year) - 3
  end

  # Karfreitag
  def self.good_friday(year = 2016)
    easter(year) - 2
  end

  def self.morgenstraich(year = 2016)
    easter(year) - 41
  end
end
