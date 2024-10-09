APPLICATION_NAME	= "Lunchtime Looser's"
APPLICATION_VERSION = "0.2.0"

STATUS_DRAFT	= 1
STATUS_RELEASED	= 2
STATUS_COMPLETED	= 3
STATUS_CANCELLED	= 10

STATUS_ACTIVE	= 4
STATUS_INACTIVE	= 5

STATUS_ACCEPTED	= 6
STATUS_TENTATIVE	= 7
STATUS_DECLINED	= 8
STATUS_NO_RESPONSE	= 9

# used for guest note visualization
STATUS_ALL = [STATUS_TENTATIVE, STATUS_DECLINED, STATUS_NO_RESPONSE]

TIME_INVITATION_TO_EVENT = 60
TIME_CANCEL_TO_EVENT	= 30
TIME_INVITATION_TO_CANCEL = 30

PAGINATION_PAGE_SIZE = 50

# set/reset password when forgotten
ALLOWED_TIME_IN_HOURS_TO_SET_PASSWORD = 2

# for export/import
APPLICATION_MODELS = %w[Type Status Person Team Group Member Event Invitee Comment Holiday Job]

Time::DATE_FORMATS[:default] = "%Y-%m-%d %H:%M"

# core extensions
Dir[File.join(Rails.root, "lib", "core_ext", "*.rb")].sort.each { |l| require l }
