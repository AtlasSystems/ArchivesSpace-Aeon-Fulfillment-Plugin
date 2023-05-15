class ExtendedRequestClient < ArchivesSpaceClient
    def get_location(location_id)
        url = build_url("#{location_id}")
        results = do_search(url, true)
        results
    end
end