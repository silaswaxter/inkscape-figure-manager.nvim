local common_utils = {}

-- Run a command using vim's builtin jobs so that its async (vim is still
-- interactive).
function common_utils.vim_start_standard_buffered_job(command)
  local job = {responses = {}, job_id = nil}
  local add_command_data = function(channel_handle, data, stream_name)
    job.responses[stream_name] = data
  end

  local exit_cb = function(channel_handle, data, stream_name)
    for i, v in ipairs(job.responses.stderr) do print(v) end
  end

  job.job_id = vim.fn.jobstart(command, {
    -- wait for stream close before invoking callbacks
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = add_command_data,
    on_stderr = add_command_data,
    on_exit = exit_cb
  })
  return job
end

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

-- Copy file using OS's utility (eg `cp` for linux)
function common_utils.copy_file(source_file_absolute_path,
                                destination_file_absolute_path)
  os.execute(common_utils.concat_with_spaces({
    'cp', source_file_absolute_path, destination_file_absolute_path
  }))
end

-- Quick and dirty method that blocks execution for a number of seconds specified
-- by time_s
function common_utils.busy_wait(time_s)
  local sec = tonumber(os.clock() + time_s);
  while (os.clock() < sec) do end
end

return common_utils
