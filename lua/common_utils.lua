local common_utils = {}

function common_utils.sanitize_error_message(error_message)
  if error_message == nil then
    return "error message nil."
  else
    return error_message
  end
end

function common_utils.concat_with_spaces(words)
  local string = ''
  if #words == 0 then
    return string
  end
  string = words[1]
  for i = 2, #words, 1 do
    string = string .. ' ' .. words[i]
  end
  return string
end

return common_utils
