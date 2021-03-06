module Audumbla
  ##
  # Enrich a specific field or list of fields, setting the property to the
  # supplied value
  module FieldEnrichment
    include Enrichment

    ##
    # The main enrichment method; runs the enrichment against a stated
    # set of fields for a record.
    #
    # This is a narrower case of `Audumbla::Enrichment` which runs the
    # enrichment against each of the specified fields in turn, setting
    # the field's value to the result.
    #
    # For example:
    #
    #   delete_empty_string_literals.enrich(record,
    #     {:sourceResource => {:creator => :name}})
    #
    # To apply the enrichment across all fields, leave the fields parameter
    # empty, or use `:all`:
    #
    #   delete_empty_string_literals.enrich(record)
    #   delete_empty_string_literals.enrich(record, :all)
    #
    # @see Audumbla::Enrichment#enrich for documentation about field
    #   formatting
    #
    # @param record [ActiveTriples::Resource] the record to enrich
    # @param fields [Array] the fields on which to apply the enrichment
    # @return [ActiveTriples::Resource] the enriched record
    def enrich(record, *fields)
      record = record.clone
      return enrich_all(record) if fields.empty? || fields == [:all]
      fields.each { |f| enrich_field(record, field_to_chain(f)) }
      record
    end

    def enrich_field(record, field_chain)
      field = field_chain.first
      return record unless record.respond_to? field
      values = record.send(field)
      if field_chain.length == 1
        new_values = values.map { |v| enrich_value(v) }
        # We call #flatten twice, since under some circumstances it fails on 
        # nested #to_ary calls the first time. This appears to be related to:
        #
        # http://yehudakatz.com/2010/01/02/the-craziest-fing-bug-ive-ever-seen/
        #   and
        # https://bugs.ruby-lang.org/issues/2494
        begin
          new_values = new_values.flatten.compact
        rescue
          new_values = new_values.flatten.compact
        end

        record.send("#{field}=".to_sym, new_values)
      else
        resources(values).each { |v| enrich_field(v, field_chain[1..-1]) }
      end
      record
    end

    def enrich_all(record)
      list_fields(record).each do |field|
        enrich_field(record, field_to_chain(field))
      end
      record
    end
  end
end
