local common_utils = {}

-- Sanitize error messages by printing when the error message is nil.
-- Useful when asserting that a function call which returns the common
-- 3 values (ie return_code, error_message, erno) succeeded.
function common_utils.sanitize_error_message(error_message)
  if error_message == nil then
    return "error message nil."
  else
    return error_message
  end
end

-- Converts a table of words into a space-seperated string
function common_utils.concat_with_spaces(words)
  local string = ''
  if #words == 0 then return string end
  string = words[1]
  for i = 2, #words, 1 do string = string .. ' ' .. words[i] end
  return string
end

-- Quick and dirty method that blocks execution for a number of seconds specified
-- by time_s
function common_utils.busy_wait(time_s)
  local sec = tonumber(os.clock() + time_s);
  while (os.clock() < sec) do end
end

return common_utils
