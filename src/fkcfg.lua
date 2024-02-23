#!/usr/bin/env lua5.4

--[[
--	fkcfg
--	/src/fkcfg.lua
--	This file is distributed under MIT License.
--	Copyright (c) 2024 Yao Zi. All rights reserved.
--]]

local io		= require "io";
local string		= require "string";
local table		= require "table";
local math		= require "math";
local os		= require "os";

local insert, tointeger = table.insert, math.tointeger;
local function
toJSONSub(b, o)
	local t = type(o);
	if t == "nil" then
		insert(b, "null");
	elseif t == "string" or t == "boolean" then
		insert(b, ("%q"):format(o));
	elseif t == "number" then
		insert(b, tostring(o));
	elseif t == "table" then
		if o[0] then	-- an array
			insert(b, "[");
			for i = 1, #o do
				toJSONSub(b, o[i]);
				insert(b, ",");
			end
			b[#b] = nil;	-- remove trailing comma
			insert(b, "]");
		else
			insert(b, "{");
			for k, v in pairs(o) do
				insert(b, ([["%s":]]):format(k));
				toJSONSub(b, v);
				insert(b, ",");
			end
			b[#b] = nil;	-- remove trailing comma
			insert(b, "}");
		end
	end

	return;
end

local function
toJSON(cfg)
	local buffer = {};
	local ok, err = pcall(toJSONSub, buffer, cfg);
	return ok and table.concat(buffer), err;
end

local function
toLuaSub(b, o)
	local t = type(o);
	if t == "table" then
		if o[0] then
			insert(b, "{");
			for _, v in ipairs(o) do
				toLuaSub(b, v);
				insert(b, ",");
			end
			insert(b, "}");		-- trailing comma is allowed
		else
			insert(b, "{");
			for k, v in pairs(o) do
				insert(b, ([==[["%s"] = ]==]):
					  format(tostring(k)));
				toLuaSub(b, v);
				insert(b, ",");
			end
			insert(b, "}");		-- trailing comma is allowed
		end
	else
		insert(b, ("%q"):format(o));
	end
end

local function
toLua(cfg)
	local buffer = {};
	local ok, err = pcall(toLuaSub, buffer, cfg);
	return ok and table.concat(buffer), err;
end

if #arg ~= 1 then
	io.stderr:write(("Usage: %s CONF_SCRIPT\n"):format(arg[0]));
	os.exit(-1);
end

local script, msg = loadfile(arg[1], "t", setmetatable({}, { __index = _G }));
if not script then
	io.stderr:write(("Cannot load script: %s\n"):format(msg));
	os.exit(-1);
end

local ok, ret1, ret2 = pcall(script);
if not ok
then
	io.stderr:write(("Script fails to run: %s"):format(ret1));
	os.exit(-1);
else
	if ret2 == "json" then
		print((toJSON(ret1)));
	elseif ret2 == "lua" then
		print((toLua(ret1)));
	else
		io.stderr:write(("Unsupported configuration format: %s"):
				format(ret2));
	end
end
