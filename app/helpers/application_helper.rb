module ApplicationHelper

  def button_classes(variant = :none, size = :md)
    base = "inline-flex items-center gap-2 px-2 py-2 rounded text-sm font-medium transition hover:cursor-pointer"

    base += case variant
    when :primary
      " text-blue-500 hover:bg-blue-300"
    when :danger
      " text-red-500 hover:bg-red-300"
    else
      " hover:bg-white-100 hover:bg-gray-300"
    end

    base
  end
end