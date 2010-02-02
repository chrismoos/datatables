module DataTablesHelper
  def datatables(source, *attrs)
    datatable = @controller.datatable_source(source)
    html_opts = []
    if attrs.last
      attrs.last.each { |k,v| html_opts << "#{k}=\"#{v}\"" }
    end
    html_opts = html_opts.join(' ')
    
    columns = datatable[:attrs].collect { |a| "<th>#{a}</th>" }
    columns.flatten!
    table_header = "<tr>#{columns}</tr>"
    url = method("#{datatable[:action]}_url".to_sym).call
"
<script>
$(document).ready(function() {
  $('##{datatable[:action]}').dataTable({
    bJQueryUI: true,
    bProcessing: true,
    bSort: false,
    bFilter: false,
		bServerSide: true,
		bAutoWidth: false,
		sAjaxSource: \"#{url}\"
  });
});
</script>
<table id=\"#{datatable[:action]}\" #{html_opts}>
<thead>
#{table_header}
</thead>
<tbody>
</tbody>
</table>
"
  end
end