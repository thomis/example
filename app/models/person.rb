class Person < ApplicationRecord
  has_secure_password

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :last_name, :first_name, :nick_name, :email, presence: true
  validates_format_of :email, with: /\A[_a-zA-Z0-9-]+(\.[_a-zA-Z0-9-]+)*@[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*\.(([0-9]{1,3})|([a-zA-Z]{2,3})|(aero|coop|info|museum|name))\z/
  validates :email, :nick_name, uniqueness: true
  validates :password, format: { with: /\A(?=.*[a-zA-Z])(?=.*[0-9]).{6,}\z/, multiline: true, message: "must have least 6 characters and must include at least one number and one letter" }, allow_nil: true

  before_create { generate_token(:auth_token) }

  belongs_to :status
  belongs_to :creator, class_name: "Person", foreign_key: "creator_id"
  belongs_to :updator, class_name: "Person", foreign_key: "updator_id"

  has_many :members
  has_many :groups, through: :members

  has_many :invitees
  has_many :events, through: :invitees
  has_many :comments

  scope :list, -> { where("id > 0") }

  scope :active, -> { where(status_id: STATUS_ACTIVE) }
  scope :inactive, -> { where(status_id: STATUS_INACTIVE) }

  scope :sorted, -> { order([ :last_name, :first_name ]) }

  def self.as_select_list
    Person.list.sorted.map { |person| [ person.full_name, person.id ] }
  end

  def inactive?
    status_id == STATUS_INACTIVE
  end

  def active?
    status_id == STATUS_ACTIVE
  end

  def full_name
    last_name + " " + first_name
  end

  def has_error?(attribute)
    " has-error" if errors.include?(attribute)
  end

  def administrator?
    return false if roles.nil?
    roles.split(",").include?("administrator")
  end

  def administrator
    return false if roles.nil?
    roles.split(",").include?("administrator")
  end

  def administrator=(n)
    roles = []
    roles << "administrator" if n == "1"
    roles << "user"
    self.roles = roles.join(",")
  end

  def generate_token(column)
    loop do
      self[column] = SecureRandom.urlsafe_base64
      break unless Person.exists?(column => self[column])
    end
  end

  def send_password_reset
    generate_token(:password_reset_token)
    self.password_reset_sent_at = Time.zone.now
    save!
    PersonMailer.password_reset(self).deliver
  end

  def statistics
    data = [ 0, 0, 0, 0 ]

    Person.connection.select_all("select
        i.person_id, i.status_id, count(*) n
      from
        invitees i inner join events e
        on i.event_id = e.id and e.status_id in (3,10)
      where
        i.person_id = #{id}
      group by
        i.person_id, i.status_id
      order by
        i.person_id, i.status_id").rows.each do |row|
      data[0] = row[2].to_i if row[1].to_i == STATUS_ACCEPTED
      data[1] = row[2].to_i if row[1].to_i == STATUS_TENTATIVE
      data[2] = row[2].to_i if row[1].to_i == STATUS_DECLINED
      data[3] = row[2].to_i if row[1].to_i == STATUS_NO_RESPONSE
    end

    data
  end

  def self.load_from_text(buffer)
    persons = []
    nick_names = []

    pattern = /([_a-zA-Z0-9-]+(\.[_a-zA-Z0-9-]+)*@[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*\.(([0-9]{1,3})|(aero|coop|info|museum|name)|([a-zA-Z]{2,3})))/

    buffer.scan(pattern).each do |m|
      email = m[0].downcase
      all = email.split("@")[0]

      first_name = my_capitalize(all.split(".")[0])

      last_name = my_capitalize(all.split(".")[1..].join(" "))
      last_name = first_name if last_name.size == 0

      nick_name = first_name
      # check and make nick name unique
      i = 1
      while Person.where(nick_name: nick_name).size > 0 || nick_names.include?(nick_name)
        nick_name = "#{first_name} #{i += 1}"
      end

      nick_names << nick_name

      # generate a random password to be stored, sometimes we get numbers only
      password = nil
      loop do
        password = SecureRandom.urlsafe_base64
        break if password.match?(/^(?=.*[a-zA-Z])(?=.*[0-9]).{6,}$/)
      end

      persons << Person.new(email: email, first_name: first_name, last_name: last_name, nick_name: nick_name, password: password, status_id: STATUS_ACTIVE, roles: "user")
    end
    persons
  end

  def self.my_capitalize(name)
    name.split(/( |_|-)/).each_slice(2).map { |m|
      if m.size == 1
        m[0].capitalize
      else
        [ m[0].capitalize, m[1].tr("_", " ") ]
      end
    }.flatten.join
  end
end
