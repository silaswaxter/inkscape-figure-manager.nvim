local common_utils = require('common_utils')
local InkscapeController = {}

-- Export the figure
function InkscapeController.export_figure(figure_absolute_path)
  -- Blocking call
  return os.execute(common_utils.concat_with_spaces({
    'inkscape', figure_absolute_path, '--export-area-page', '--export-dpi=300',
    '--export-type=png', '&'
  }))
end

return InkscapeController
