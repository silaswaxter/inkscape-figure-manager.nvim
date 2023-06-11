local common_utils = {}

function common_utils.sanitize_error_message(error_message)
  if error_message == nil then
    return "error message nil."
  else
    return error_message
  end
end

return common_utils
