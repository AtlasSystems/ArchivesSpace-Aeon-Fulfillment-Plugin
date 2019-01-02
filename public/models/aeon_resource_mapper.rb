class AeonResourceMapper < AeonArchivalObjectMapper

    register_for_record_type(Resource)

    def initialize(resource)
        super(resource)
    end
    
end
