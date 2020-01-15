class GroupFormat < Redmine::FieldFormat::RecordList
  add 'group'
  self.form_partial = 'custom_fields/formats/group'
  field_attributes :user_role

  def possible_values_options(custom_field, object=nil)
    possible_values_records(custom_field, object).map {|u| [u.name, u.id.to_s]}
  end

  def possible_values_records(custom_field, object=nil)
    Group.active
  end

  def value_from_keyword(custom_field, keyword, object)
    groups = possible_values_records(custom_field, object).to_a
    parse_keyword(custom_field, keyword) do |k|
      Principal.detect_by_keyword(groups, k).try(:id)
    end
  end

  def before_custom_field_save(custom_field)
    super
    if custom_field.user_role.is_a?(Array)
      custom_field.user_role.map!(&:to_s).reject!(&:blank?)
    end
  end

  def query_filter_values(custom_field, query)
    query.author_values
  end
end