module ApplicationHelper
  def get_header_classes(controller)
    case "#{controller.controller_name}##{controller.action_name}"
    when "events#show"
      "bg-slate-700"
    else
      "bg-slate-500/30 backdrop-blur-lg"
    end
  end
end
