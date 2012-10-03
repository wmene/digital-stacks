
# Depends on the #request.path method from Sinatra::Base
module IiifTranslator
  
  def translate
    parse_request
    if(@iiif_params[:info])
      return [@iiif_params[:id] + '.' + @iiif_params[:format], '']
    end
    new_params = {}
    new_params.merge! trans_region
    new_params.merge! trans_size
    new_params.merge! trans_rotate
    new_query = new_params.map{|k,v| "#{k}=#{v}" }.join("&")
    id = @iiif_params[:id]
    id << '.' << @iiif_params[:format] if @iiif_params[:format]
    [id, new_query]
  end

  # Takes the raw path from request.path, parses out, and sets @iiif_params hash
  # Uses request.path
  def parse_request
    p = request.path.split('iiif/').pop.split('/')
    escaped_id = CGI::unescape(p[0])
    if(p[1] =~ /^info\.(json|xml)$/)
      @iiif_params = {
        :id        => escaped_id,
        :info      => true,
        :format    => $1
      }
      return
    else
      @iiif_params = {
        :id        => escaped_id,
        :region    => p[1],
        :size      => p[2],
        :rotate    => p[3],
      }
    end
    q_f = p[4].split('.')
    @iiif_params[:quality] = q_f.first
    @iiif_params[:format] = q_f.last unless(q_f.size == 1)
  end

  def trans_region
    r = @iiif_params[:region]
    case r
    when 'full'
      @iiif_params[:id] += '_full'
      return {}
    when /\d+,\d+,\d+,\d+/
      return { :region => r }
    end
  end
  
  def trans_size
    s = @iiif_params[:size]
    case s
    when 'full'
      return {}
    when /^(\d+),$/
      return {:w => $1}
    when /^,(\d+)$/
      return {:h => $1}
    # when /^pct:(\d+)$/
    #   return {:zoom => $1}
    when /^(\d+),(\d+)$/
      return {:w => $1, :h => $2}
    end
  end
  
  def trans_rotate
    r = @iiif_params[:rotate]
    return {} if r == '0'
    {:rotate => r}
  end
  
end