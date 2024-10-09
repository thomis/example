class Ability
  include CanCan::Ability

  def initialize(person)
    return unless person

    can :mana, :all

    # if person.administrator
    #     can :manage, :all
    # else
    #   can [:show,:index], Event do |event|
    #     event.person_ids.include?(person.id)                # only for events I'm invited
    #   end
    #   can [:show,:edit,:update], Person, id: person.id      # only for your own person record
    # end
  end
end
