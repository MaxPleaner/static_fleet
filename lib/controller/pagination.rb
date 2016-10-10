module Pagination
  LimitMax = 500
  
  def self.paginate(query, limit=nil, offset=nil)
    limit && query = query.limit([limit, LimitMax].min)
    offset && query = query.offset(offset)
    query
  end
end
