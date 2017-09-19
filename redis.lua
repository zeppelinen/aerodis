local MAX_INT = 4294967294 - 2

local function EXISTS(rec, bin)
	if aerospike:exists(rec)
		and rec[bin] ~= nil
			and type(rec) == "userdata"
				and record.ttl(rec) < (MAX_INT - 60) then
		return true
	end
	return false
end

local function UPDATE(rec)
	if aerospike:exists(rec) then
		aerospike:update(rec)
	else
		aerospike:create(rec)
	end
end

function FLUSHDB(rec)
	aerospike:remove(rec)
end

local function ARRAY_RANGE (rec, bin, start, stop)
	if (EXISTS(rec, bin)) then
		local l = rec[bin]
		local switch = 0

		if (start < 0) then
			start = #l + start
			switch = switch + 1
		end

		if (stop < 0) then
			stop = #l + stop
			switch = switch + 1
		end

		if ((start > stop) and (switch == 1)) then
			local tmp = stop
			stop = start
			start = tmp
		end

		if (start == stop) then
			if (start == 0) and (#l == 0) then
				return list()
			end
			local v = l[start + 1]
			local l = list()
			list.prepend(l, v)
			return l
		elseif (start < stop) then
			local pre_list  = list.drop(l, start)
			if pre_list == nil then
			  pre_list = l
			end
			local post_list = list.take(pre_list, stop - start + 1)
			return post_list
		end
	end
	return list()
end

function LRANGE (rec, bin, start, stop)
	return ARRAY_RANGE(rec, bin, start, stop)
end

function LTRIM (rec, bin, start, stop)
	if (EXISTS(rec, bin)) then
		rec[bin] = ARRAY_RANGE(rec, bin, start, stop)
		local length = #rec[bin]
		if (length == 0) then
			rec[bin .. '_size'] = nil
		else
			rec[bin .. '_size'] = length
		end
		UPDATE(rec)
	end
	return "OK"
end

function HSET (rec, bin, value)
	local created = 1
	if (EXISTS(rec, bin)) then
		created = 0
	end
	rec[bin] = value
	UPDATE(rec)
	return created
end

function HDEL (rec, bin)
	if (EXISTS(rec, bin)) then
		rec[bin] = nil
		UPDATE(rec)
		return 1
	end
	return 0
end
