module ChangedAttributes

  IGNORE_ATTRS = ['updated_at', 'created_at', 'next_occurrence', 'invited_members', 'invited_non_members', 'duration', 'recurrence_frequency', 'runt_expression', 'is_public']
  def get_changed_attributes(old_attributes)
    changed_attributes = {}
    old_attributes.each_key do |key| 
      current_value = (self.attributes[key] || self.send(key))
      unless(old_attributes[key] == current_value || IGNORE_ATTRS.include?(key))
        if key =~ /(\w+)_id/
          begin
          assoc_attribute = $1
          model_class = Kernel.const_get(assoc_attribute.camelize)
          changed_attributes[assoc_attribute] = { }
          changed_attributes[assoc_attribute]['old'] = model_class.find(old_attributes[key]).name
          changed_attributes[assoc_attribute]['new'] = model_class.find(self.attributes[key]).name
          rescue
            #puts "Skipping #{assoc_attribute} in changed_attributes list: #{ $!}"
          end
        else
          changed_attributes[key] = {}
          changed_attributes[key]['old'] = old_attributes[key]
          changed_attributes[key]['new'] = current_value
        end 
      end 
    end 
    return changed_attributes
  end

end
