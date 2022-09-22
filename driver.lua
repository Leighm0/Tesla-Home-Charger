require "json"
JSON=(loadstring(json.JSON_LIBRARY_CHUNK))()

------------------------------
-- // GLOBAL Tables & Strings.
------------------------------
do
	debugMode = 0
	PROXY_ID = 5001
	EC = {}
	LUA_ACTION = {}
	OPC = {}
	RFP = {}
end	

-------------------------------
-- // TESLA Tables & Strings.
-------------------------------
TESLA = {
	IP = '',
	POLL_INTERVAL = '',
	CONNECTION_STATUS = '',
	-- Session Vitals
	CONTACTOR_CLOSED = false,
	VEHICLE_CONNECTED = false,
	SESSION_S = 0,
	GRID_V = 0,
	GRID_HZ = 0,
	VEHICLE_CURRENT_A = 0,
	CURRENTA_A = 0,
	CURRENTB_A = 0,
	CURRENTC_A = 0,
	CURRENTN_A = 0,
	VOLTAGEA_V = 0,
	VOLTAGEB_V = 0,
	VOLTAGEC_V = 0,
	RELAY_COIL_V = 0,
	PCBA_TEMP_C = 0,
	HANDLE_TEMP_C = 0,
	MCU_TEMP_C = 0,
	VITALS_UPTIME_S = 0,
	INPUT_THERMOPILE_UV = 0,
	PROX_V = 0,
	PILOT_HIGH_V = 0,
	PILOT_LOW_V = 0,
	SESSION_ENERGY_WH = 0,
	CONFIG_STATUS = 0,
	EVSE_STATE = 0,
	CURRENT_ALERTS = '',
	-- Lifetime Stats
	CONTACTOR_CYCLES = 0,
	CONTACTOR_CYCLES_LOADED = 0,
	ALERT_COUNT = 0,
	THERMAL_FOLDBACKS = 0,
	AVG_STARTUP_TEMP = 0,
	CHARGE_STARTS = 0,
	ENERGY_WH = 0,
	CONNECTOR_CYCLES = 0,
	LIFETIME_UPTIME_S = 0,
	CHARGING_TIME_S = 0,
	-- Wifi Status
	WIFI_SSID = '',
	WIFI_SIGNAL_STRENGTH = 0,
	WIFI_RSSI = 0,
	WIFI_SNR = 0,
	WIFI_CONNECTED = false,
	WIFI_INFRA_IP = '',
	INTERNET = false,
	WIFI_MAC = '',
	-- Version
	FIRMWARE_VERSION = '',
	PART_NUMBER = '',
	SERIAL_NUMBER = '',
}

---------------------------------
-- // TESLA Specific Functions.
---------------------------------
function TESLA.RETURN_HEADERS()
	local headers = {
		["Content-Type"] = "application/json"
	}
	return headers
end

function TESLA.STATUS(Status)
	TESLA.CONNECTION_STATUS = Status
	if (Status == 'OFFLINE') then
		if (pollTimer ~= nil) then
			C4:KillTimer(pollTimer)
			pollTimer = nil
		end
		if (reconnectTimer ~= nil) then
			C4:KillTimer(reconnectTimer)
			reconnectTimer = nil
		end
		reconnectTimer = C4:AddTimer(60, "SECONDS", false)
		if (TESLA.CONNECTION_STATUS ~= nil) then 
			C4:UpdateProperty("Connection Status", tostring(TESLA.CONNECTION_STATUS))
			C4:SetVariable("CONNECTION_STATUS", tostring(TESLA.CONNECTION_STATUS))
		end
	elseif (Status == 'ONLINE') then
		if (pollTimer ~= nil) then
			C4:KillTimer(pollTimer)
			pollTimer = nil
		end
		pollTimer = C4:AddTimer(TESLA.POLL_INTERVAL, "SECONDS", false)
		if (reconnectTimer ~= nil) then
			C4:KillTimer(reconnectTimer)
			reconnectTimer = nil
		end
		if (TESLA.CONNECTION_STATUS ~= nil) then 
			C4:UpdateProperty("Connection Status", tostring(TESLA.CONNECTION_STATUS))
			C4:SetVariable("CONNECTION_STATUS", tostring(TESLA.CONNECTION_STATUS))
		end
	end
end

function TESLA.POLL()
	if(string.len(TESLA.IP) > 5) then
		C4:urlGet(string.format("http://%s/api/1/vitals", TESLA.IP), TESLA.RETURN_HEADERS(), false, TESLA.PROCESS_VITALS)
		C4:urlGet(string.format("http://%s/api/1/lifetime", TESLA.IP), TESLA.RETURN_HEADERS(), false, TESLA.PROCESS_LIFETIME)
		C4:urlGet(string.format("http://%s/api/1/wifi_status", TESLA.IP), TESLA.RETURN_HEADERS(), false, TESLA.PROCESS_WIFI_STATUS)
		C4:urlGet(string.format("http://%s/api/1/version", TESLA.IP), TESLA.RETURN_HEADERS(), false, TESLA.PROCESS_VERSION)
	end
end

function TESLA.PROCESS_VITALS(ticketId, strData, responseCode, tHeaders, strError)
	if (strError == nil) then
		if(responseCode == 200) then
			local data = JSON:decode(strData)
			-- CONTACTOR_CLOSED
			if (data.contactor_closed ~= nil) and (TESLA.CONTACTOR_CLOSED ~= data.contactor_closed) then
				TESLA.CONTACTOR_CLOSED = data.contactor_closed or false
				if (TESLA.CONTACTOR_CLOSED == true) then
					C4:SetVariable("VEHICLE_CHARGING", '1')
				else
					C4:SetVariable("VEHICLE_CHARGING", '0')
				end
				C4:UpdateProperty("Vehicle Charging", tostring(TESLA.CONTACTOR_CLOSED))
			end
			-- VEHICLE_CONNECTED
			if (data.vehicle_connected ~= nil) and (TESLA.VEHICLE_CONNECTED ~= data.vehicle_connected) then
				TESLA.VEHICLE_CONNECTED = data.vehicle_connected or false
				if (TESLA.VEHICLE_CONNECTED == true) then
					C4:SetVariable("VEHICLE_CONNECTED", '1')
				else
					C4:SetVariable("VEHICLE_CONNECTED", '0')
				end
				C4:UpdateProperty("Vehicle Connected", tostring(TESLA.VEHICLE_CONNECTED))
			end
			-- SESSION_S
			if (data.session_s ~= nil) and (TESLA.SESSION_S ~= data.session_s) then
				TESLA.SESSION_S = data.session_s or 0
				C4:SetVariable("SESSION_TIME", TESLA.SESSION_S)
				C4:UpdateProperty("Current Session Time", tostring(BuildTime(TESLA.SESSION_S)))
			end
			-- GRID_V
			if (data.grid_v ~= nil) and (TESLA.GRID_V ~= data.grid_v) then
				TESLA.GRID_V = data.grid_v or 0
				C4:SetVariable("GRID_VOLTAGE", TESLA.GRID_V)
				C4:UpdateProperty("Measured Grid Voltage (V)", tostring(TESLA.GRID_V))
			end
			-- GRID_HZ
			if (data.grid_hz ~= nil) and (TESLA.GRID_HZ ~= data.grid_hz) then
				TESLA.GRID_HZ = data.grid_hz or 0
				C4:SetVariable("GRID_FREQUENCY", TESLA.GRID_HZ)
				C4:UpdateProperty("Measured Grid Frequency (Hz)", tostring(TESLA.GRID_HZ))
			end
			-- VEHICLE_CURRENT_A
			if (data.vehicle_current_a ~= nil) and (TESLA.VEHICLE_CURRENT_A ~= data.vehicle_current_a) then
				TESLA.VEHICLE_CURRENT_A = data.vehicle_current_a or 0
				C4:SetVariable("VEHICLE_CURRENT", TESLA.VEHICLE_CURRENT_A)
				C4:UpdateProperty("Measured Vehicle Current (A)", tostring(TESLA.VEHICLE_CURRENT_A))
			end
			-- CURRENTA_A
			if (data.currentA_a ~= nil) and (TESLA.CURRENTA_A ~= data.currentA_a) then
				TESLA.CURRENTA_A = data.currentA_a or 0
				C4:SetVariable("CURRENT_PHASE_1", TESLA.CURRENTA_A)
				C4:UpdateProperty("Measured Current Phase 1 (A)", tostring(TESLA.CURRENTA_A))
			end
			-- CURRENTB_A
			if (data.currentB_a ~= nil) and (TESLA.CURRENTB_A ~= data.currentB_a) then
				TESLA.CURRENTB_A = data.currentB_a or 0
				C4:SetVariable("CURRENT_PHASE_2", TESLA.CURRENTB_A)
				C4:UpdateProperty("Measured Current Phase 2 (A)", tostring(TESLA.CURRENTB_A))
			end
			-- CURRENTC_A
			if (data.currentA_a ~= nil) and (TESLA.CURRENTC_A ~= data.currentC_a) then
				TESLA.CURRENTC_A = data.currentC_a or 0
				C4:SetVariable("CURRENT_PHASE_3", TESLA.CURRENTC_A)
				C4:UpdateProperty("Measured Current Phase 3 (A)", tostring(TESLA.CURRENTC_A))
			end
			-- CURRENTN_A
			if (data.currentN_a ~= nil) and (TESLA.CURRENTN_A ~= data.currentN_a) then
				TESLA.CURRENTN_A = data.currentN_a or 0
				C4:SetVariable("CURRENT_NEUTRAL", TESLA.CURRENTN_A)
				C4:UpdateProperty("Measured Current Neutral (A)", tostring(TESLA.CURRENTN_A))
			end
			-- VOLTAGEA_V
			if (data.voltageA_v ~= nil) and (TESLA.VOLTAGEA_V ~= data.voltageA_v) then
				TESLA.VOLTAGEA_V = data.voltageA_v or 0
				C4:SetVariable("VOLTAGE_PHASE_1", TESLA.VOLTAGEA_V)
				C4:UpdateProperty("Measured Voltage Phase 1 (V)", tostring(TESLA.VOLTAGEA_V))
			end
			-- VOLTAGEB_V
			if (data.voltageB_v ~= nil) and (TESLA.VOLTAGEB_V ~= data.voltageB_v) then
				TESLA.VOLTAGEB_V = data.voltageB_v or 0
				C4:SetVariable("VOLTAGE_PHASE_2", TESLA.VOLTAGEB_V)
				C4:UpdateProperty("Measured Voltage Phase 2 (V)", tostring(TESLA.VOLTAGEB_V))
			end
			-- VOLTAGEC_V
			if (data.voltageC_v ~= nil) and (TESLA.VOLTAGEC_V ~= data.voltageC_v) then
				TESLA.VOLTAGEC_V = data.voltageC_v or 0
				C4:SetVariable("VOLTAGE_PHASE_3", TESLA.VOLTAGEC_V)
				C4:UpdateProperty("Measured Voltage Phase 3 (V)", tostring(TESLA.VOLTAGEC_V))
			end
			-- RELAY_COIL_V
			if (data.relay_coil_v ~= nil) and (TESLA.RELAY_COIL_V ~= data.relay_coil_v) then
				TESLA.RELAY_COIL_V = data.relay_coil_v or 0
				C4:SetVariable("RELAY_COIL_VOLTAGE", TESLA.RELAY_COIL_V)
				C4:UpdateProperty("Relay Coil Voltage (V)", tostring(TESLA.RELAY_COIL_V))
			end
			-- PCBA_TEMP_C
			if (data.pcba_temp_c ~= nil) and (TESLA.PCBA_TEMP_C ~= data.pcba_temp_c) then
				TESLA.PCBA_TEMP_C = data.pcba_temp_c or 0
				C4:SetVariable("PCBA_TEMP", TESLA.PCBA_TEMP_C)
				C4:UpdateProperty("PCBA Temp (C)", tostring(TESLA.PCBA_TEMP_C))
			end
			-- HANDLE_TEMP_C
			if (data.handle_temp_c ~= nil) and (TESLA.HANDLE_TEMP_C ~= data.handle_temp_c) then
				TESLA.HANDLE_TEMP_C = data.handle_temp_c or 0
				C4:SetVariable("HANDLE_TEMP", TESLA.HANDLE_TEMP_C)
				C4:UpdateProperty("Handle Temp (C)", tostring(TESLA.HANDLE_TEMP_C))
			end
			-- MCU_TEMP_C
			if (data.mcu_temp_c ~= nil) and (TESLA.MCU_TEMP_C ~= data.mcu_temp_c) then
				TESLA.MCU_TEMP_C = data.mcu_temp_c or 0
				C4:SetVariable("MCU_TEMP", TESLA.MCU_TEMP_C)
				C4:UpdateProperty("MCU Temp (C)", tostring(TESLA.MCU_TEMP_C))
			end
			-- VITALS_UPTIME_S
			if (data.uptime_s ~= nil) and (TESLA.VITALS_UPTIME_S ~= data.uptime_s) then
				TESLA.VITALS_UPTIME_S = data.uptime_s or 0
				C4:SetVariable("SESSION_UPTIME", TESLA.VITALS_UPTIME_S)
				C4:UpdateProperty("Wall Charger Uptime", tostring(BuildTime(TESLA.VITALS_UPTIME_S)))
			end
			-- INPUT_THERMOPILE_UV
			if (data.input_thermopile_uv ~= nil) and (TESLA.INPUT_THERMOPILE_UV ~= data.input_thermopile_uv) then
				TESLA.INPUT_THERMOPILE_UV = data.input_thermopile_uv or 0
				C4:SetVariable("INPUT_THERMOPILE_UV", TESLA.INPUT_THERMOPILE_UV)
				C4:UpdateProperty("Input Thermopile UV", tostring(TESLA.INPUT_THERMOPILE_UV))
			end
			-- PROX_V
			if (data.prox_v ~= nil) and (TESLA.PROX_V ~= data.prox_v) then
				TESLA.PROX_V = data.prox_v or 0
				C4:SetVariable("PROX_V", TESLA.PROX_V)
				C4:UpdateProperty("Prox (V)", tostring(TESLA.PROX_V))
			end
			-- PILOT_HIGH_V
			if (data.pilot_high_v ~= nil) and (TESLA.PILOT_HIGH_V ~= data.pilot_high_v) then
				TESLA.PILOT_HIGH_V = data.pilot_high_v or 0
				C4:SetVariable("PILOT_SIGNAL_HIGH_VOLTAGE", TESLA.PILOT_HIGH_V)
				C4:UpdateProperty("Pilot Signal High Voltage (V)", tostring(TESLA.PILOT_HIGH_V))
			end
			-- PILOT_LOW_V
			if (data.pilot_low_v ~= nil) and (TESLA.PILOT_LOW_V ~= data.pilot_low_v) then
				TESLA.PILOT_LOW_V = data.pilot_low_v or 0
				C4:SetVariable("PILOT_SIGNAL_LOW_VOLTAGE", TESLA.PILOT_LOW_V)
				C4:UpdateProperty("Pilot Signal Low Voltage (V)", tostring(TESLA.PILOT_LOW_V))
			end
			-- SESSION_ENERGY_WH
			if (data.session_energy_wh ~= nil) and (TESLA.SESSION_ENERGY_WH ~= data.session_energy_wh) then
				TESLA.SESSION_ENERGY_WH = data.session_energy_wh or 0
				C4:SetVariable("DELIVERED_SESSION_ENERGY", TESLA.SESSION_ENERGY_WH)
				C4:UpdateProperty("Delivered Session Energy (Wh)", tostring(TESLA.SESSION_ENERGY_WH))
			end
			-- CONFIG_STATUS
			if (data.config_status ~= nil) and (TESLA.CONFIG_STATUS ~= data.config_status) then
				TESLA.CONFIG_STATUS = data.config_status or 0
				C4:SetVariable("CONFIG_STATUS", TESLA.CONFIG_STATUS)
				C4:UpdateProperty("Config Status", tostring(TESLA.CONFIG_STATUS))
			end
			-- EVSE_STATE
			if (data.evse_state ~= nil) and (TESLA.EVSE_STATE ~= data.evse_state) then
				TESLA.EVSE_STATE = data.evse_state or 0
				C4:SetVariable("WALL_CHARGER_STATE", TESLA.EVSE_STATE)
				C4:UpdateProperty("Wall Charger State", tostring(TESLA.EVSE_STATE))
			end
			-- CURRENT_ALERTS
			if (data.current_alerts ~= nil) and (TESLA.CURRENT_ALERTS ~= data.current_alerts) then
				if (type(data.current_alerts) == "table") then
					local table_data = ""
					local sIndent = " "
					for k,v in pairs(data.current_alerts) do
						table_data = table_data .. tostring(k) .. sIndent .. tostring(v) .. sIndent
					end
					TESLA.CURRENT_ALERTS = table_data or ''
				else
					TESLA.CURRENT_ALERTS = data.current_alerts or ''
				end
				C4:SetVariable("CURRENT_ALERTS", tostring(TESLA.CURRENT_ALERTS))
				C4:UpdateProperty("Current Alerts", tostring(TESLA.CURRENT_ALERTS))
			end
			TESLA.STATUS("ONLINE")
		else
			TESLA.STATUS("OFFLINE")
			Dbg(string.format("PROCESS_VITALS ERROR (%s)", responseCode))
		end
	else
		Dbg("PROCESS_VITALS C4:urlGet() failed with error: " .. strError)
	end
end

function TESLA.PROCESS_LIFETIME(ticketId, strData, responseCode, tHeaders, strError)
	if (strError == nil) then
		if(responseCode == 200) then
			local data = JSON:decode(strData)
			-- Contactor Cycles
			if (data.contactor_cycles ~= nil) and (TESLA.CONTACTOR_CYCLES ~= data.contactor_cycles) then
				TESLA.CONTACTOR_CYCLES = data.contactor_cycles or 0
				C4:SetVariable("LIFETIME_CONTACTOR_CYCLES", TESLA.CONTACTOR_CYCLES)
				C4:UpdateProperty("Contactor Cycles", tostring(TESLA.CONTACTOR_CYCLES))
			end
			-- Contactor Cycles Loaded
			if (data.contactor_cycles_loaded ~= nil) and (TESLA.CONTACTOR_CYCLES_LOADED ~= data.contactor_cycles_loaded) then
				TESLA.CONTACTOR_CYCLES_LOADED = data.contactor_cycles_loaded or 0
				C4:SetVariable("LIFETIME_CONTACTOR_CYCLES_LOADED", TESLA.CONTACTOR_CYCLES_LOADED)
				C4:UpdateProperty("Contactor Cycles Loaded", tostring(TESLA.CONTACTOR_CYCLES_LOADED))
			end
			-- Alert Count
			if (data.alert_count ~= nil) and (TESLA.ALERT_COUNT ~= data.alert_count) then
				TESLA.ALERT_COUNT = data.alert_count or 0
				C4:SetVariable("LIFETIME_ALERT_COUNT", TESLA.ALERT_COUNT)
				C4:UpdateProperty("Alert Count", tostring(TESLA.ALERT_COUNT))
			end
			-- Thermal Foldbacks
			if (data.thermal_foldbacks ~= nil) and (TESLA.THERMAL_FOLDBACKS ~= data.thermal_foldbacks) then
				TESLA.THERMAL_FOLDBACKS = data.thermal_foldbacks or 0
				C4:SetVariable("LIFETIME_THERMAL_FOLDBACKS", TESLA.THERMAL_FOLDBACKS)
				C4:UpdateProperty("Thermal Foldbacks", tostring(TESLA.THERMAL_FOLDBACKS))
			end
			-- Average Startup Temperature
			if (data.avg_startup_temp ~= nil) and (TESLA.AVG_STARTUP_TEMP ~= data.avg_startup_temp) then
				TESLA.AVG_STARTUP_TEMP = data.avg_startup_temp or 0
				C4:SetVariable("LIFETIME_AVERAGE_STARTUP_TEMP", TESLA.AVG_STARTUP_TEMP)
				C4:UpdateProperty("Average Startup Temp (C)", tostring(TESLA.AVG_STARTUP_TEMP))
			end
			-- Charge Starts
			if (data.charge_starts ~= nil) and (TESLA.CHARGE_STARTS ~= data.charge_starts) then
				TESLA.CHARGE_STARTS = data.charge_starts or 0
				C4:SetVariable("LIFETIME_STARTED_CHARGES", TESLA.CHARGE_STARTS)
				C4:UpdateProperty("Number of Started Charges", tostring(TESLA.CHARGE_STARTS))
			end
			-- Energy Wh
			if (data.energy_wh ~= nil) and (TESLA.ENERGY_WH ~= data.energy_wh) then
				TESLA.ENERGY_WH = data.energy_wh or 0
				C4:SetVariable("LIFETIME_TOTAL_ENERGY_DELIVERED", TESLA.ENERGY_WH)
				C4:UpdateProperty("Total Energy Delivered (Wh)", tostring(TESLA.ENERGY_WH))
			end
			-- Connector Cycles
			if (data.connector_cycles ~= nil) and (TESLA.CONNECTOR_CYCLES ~= data.connector_cycles) then
				TESLA.CONNECTOR_CYCLES = data.connector_cycles or 0
				C4:SetVariable("LIFETIME_CONNECTOR_CYCLES", TESLA.CONNECTOR_CYCLES)
				C4:UpdateProperty("Connector Cycles", tostring(TESLA.CONNECTOR_CYCLES))
			end
			-- Uptime (Seconds)
			if (data.uptime_s ~= nil) and (TESLA.LIFETIME_UPTIME_S ~= data.uptime_s) then
				TESLA.LIFETIME_UPTIME_S = data.uptime_s or 0
				C4:SetVariable("LIFETIME_UPTIME", TESLA.LIFETIME_UPTIME_S)
				C4:UpdateProperty("Lifetime Uptime", tostring(BuildTime(TESLA.LIFETIME_UPTIME_S)))
			end
			-- Charge Time (Seconds)
			if (data.charging_time_s ~= nil) and (TESLA.CHARGING_TIME_S ~= data.charging_time_s) then
				TESLA.CHARGING_TIME_S = data.charging_time_s or 0
				C4:SetVariable("LIFETIME_TOTAL_CHARGING_TIME", TESLA.CHARGING_TIME_S)
				C4:UpdateProperty("Total Charging Time", tostring(BuildTime(TESLA.CHARGING_TIME_S)))
			end
			TESLA.STATUS("ONLINE")
		else
			TESLA.STATUS("OFFLINE")
			Dbg(string.format("PROCESS_LIFETIME ERROR (%s)",responseCode))
		end
	else
		Dbg("PROCESS_LIFETIME failed with error: " .. strError)
	end
end

function TESLA.PROCESS_WIFI_STATUS(ticketId, strData, responseCode, tHeaders, strError)
	if (strError == nil) then
		if(responseCode == 200) then
			local data = JSON:decode(strData)
			-- WIFI_SSID
			if (data.wifi_ssid ~= nil) and (TESLA.WIFI_SSID ~= data.wifi_ssid) then
				TESLA.WIFI_SSID = data.wifi_ssid or ''
				local ssid_data = C4:Decode(TESLA.WIFI_SSID, 'BASE64')
				C4:SetVariable("WIFI_SSID", tostring(ssid_data))
			end
			-- WIFI_SIGNAL_STRENGTH
			if (data.wifi_signal_strength ~= nil) and (TESLA.WIFI_SIGNAL_STRENGTH ~= data.wifi_signal_strength) then
				TESLA.WIFI_SIGNAL_STRENGTH = data.wifi_signal_strength or 0
				C4:SetVariable("WIFI_SIGNAL_STRENGTH", TESLA.WIFI_SIGNAL_STRENGTH)
			end
			-- WIFI_RSSI
			if (data.wifi_rssi ~= nil) and (TESLA.WIFI_RSSI ~= data.wifi_rssi) then
				TESLA.WIFI_RSSI = data.wifi_rssi or 0
				C4:SetVariable("WIFI_RSSI", TESLA.WIFI_RSSI)
			end
			-- WIFI_SNR
			if (data.wifi_snr ~= nil) and (TESLA.WIFI_SNR ~= data.wifi_snr) then
				TESLA.WIFI_SNR = data.wifi_snr or 0
				C4:SetVariable("WIFI_SNR", TESLA.WIFI_SNR)
			end
			-- WIFI_CONNECTED
			if (data.wifi_connected ~= nil) and (TESLA.WIFI_CONNECTED ~= data.wifi_connected) then
				TESLA.WIFI_CONNECTED = data.wifi_connected or false
				if (TESLA.WIFI_CONNECTED == true) then
					C4:SetVariable("WIFI_CONNECTED", '1')
				else
					C4:SetVariable("WIFI_CONNECTED", '0')
				end
			end
			-- WIFI_INFRA_IP
			if (data.wifi_infra_ip ~= nil) and (TESLA.WIFI_INFRA_IP ~= data.wifi_infra_ip) then
				TESLA.WIFI_INFRA_IP = data.wifi_infra_ip or '0.0.0.0'
				C4:SetVariable("WIFI_IP", tostring(TESLA.WIFI_INFRA_IP))
			end
			-- INTERNET
			if (data.internet ~= nil) and (TESLA.INTERNET ~= data.internet) then
				TESLA.INTERNET = data.internet or false
				if (TESLA.INTERNET == true) then
					C4:SetVariable("INTERNET_CONNECTED", '1')
				else
					C4:SetVariable("INTERNET_CONNECTED", '0')
				end
				C4:UpdateProperty("Internet Connected", tostring(TESLA.INTERNET))
			end
			-- WIFI_MAC
			if (data.wifi_mac ~= nil) and (TESLA.WIFI_MAC ~= data.wifi_mac) then
				TESLA.WIFI_MAC = data.wifi_mac or ''
				C4:SetVariable("WIFI_MAC", tostring(TESLA.WIFI_MAC))
				C4:UpdateProperty("MAC Address", tostring(TESLA.WIFI_MAC))
			end
			TESLA.STATUS("ONLINE")
		else
			TESLA.STATUS("OFFLINE")
			Dbg(string.format("PROCESS_WIFI_STATUS ERROR (%s)",responseCode))
		end
	else
		Dbg("PROCESS_WIFI_STATUS failed with error: " .. strError)
	end
end

function TESLA.PROCESS_VERSION(ticketId, strData, responseCode, tHeaders, strError)
	if (strError == nil) then
		if(responseCode == 200) then
			local data = JSON:decode(strData)
			-- FIRMWARE_VERSION
			if (data.firmware_version ~= nil) and (TESLA.FIRMWARE_VERSION ~= data.firmware_version) then
				TESLA.FIRMWARE_VERSION = data.firmware_version or ''
				C4:SetVariable("FIRMWARE_VERSION", tostring(TESLA.FIRMWARE_VERSION))
				C4:UpdateProperty("Firmware Version", tostring(TESLA.FIRMWARE_VERSION))
			end
			-- PART_NUMBER
			if (data.part_number ~= nil) and (TESLA.PART_NUMBER ~= data.part_number) then
				TESLA.PART_NUMBER = data.part_number or ''
				C4:SetVariable("PART_NUMBER", tostring(TESLA.PART_NUMBER))
			end
			-- SERIAL_NUMBER
			if (data.serial_number ~= nil) and (TESLA.SERIAL_NUMBER ~= data.serial_number) then
				TESLA.SERIAL_NUMBER = data.serial_number or ''
				C4:SetVariable("SERIAL_NUMBER", tostring(TESLA.SERIAL_NUMBER))
				C4:UpdateProperty("Serial Number", tostring(TESLA.SERIAL_NUMBER))
			end
			TESLA.STATUS("ONLINE")
		else
			TESLA.STATUS("OFFLINE")
			Dbg(string.format("PROCESS_VERSION ERROR (%s)",responseCode))
		end
	else
		Dbg("PROCESS_VERSION failed with error: " .. strError)
	end
end

-------------------------------------------------------------------
--Function Name : OnPropertyChanged(strProperty)
--Parameters    : strProperty(string)
--Description   : Function called when properties changed
-------------------------------------------------------------------
function OnPropertyChanged(strProperty)
	Dbg("OnPropertyChanged [" .. strProperty .. "] : " .. Properties[strProperty])
	local propertyValue = Properties[strProperty]
	local trimmedProperty = string.gsub(strProperty, " ", "")
	trimmedProperty = string.gsub(trimmedProperty, "/", "")
	trimmedProperty = string.gsub(trimmedProperty, "%(", "")
	trimmedProperty = string.gsub(trimmedProperty, "%)", "")
	local status, err
	if (OPC[strProperty] ~= nil and type(OPC[strProperty]) == "function") then
		status, err = pcall(OPC[strProperty], propertyValue)
	elseif (OPC[trimmedProperty] ~= nil and type(OPC[trimmedProperty]) == "function") then
		status, err = pcall(OPC[trimmedProperty], propertyValue)
	else
		Dbg("OnPropertyChanged: Unhandled property = " .. strProperty)
		status = true
	end
	if (not status) then
		Dbg("OPC_ERROR: " .. err)
	end
end

-------------------------------------------------------------------
-- // ON_PROPERTY_CHANGED Functions
-------------------------------------------------------------------
function OPC.DebugMode(propertyValue)
	if (propertyValue == "Off") then
		print("DEBUG MODE = OFF\r\n")
		debugMode = 0
	elseif (propertyValue == "On") then
		print("DEBUG MODE = ON\r\n")
		debugMode = 1
	end
end

function OPC.DeviceIP(propertyValue)
	TESLA.IP = propertyValue
	if (string.len(TESLA.IP) > 5) then
		TESLA.POLL()
		if(TESLA.POLL_INTERVAL ~= "0") then
			if (pollTimer ~= nil) then
				C4:KillTimer(pollTimer)
				pollTimer = nil
			end
			pollTimer = C4:AddTimer(TESLA.POLL_INTERVAL, "SECONDS", false)
		end
	end
end

function OPC.PollIntervalSeconds(propertyValue)
	TESLA.POLL_INTERVAL = propertyValue
	if (string.len(TESLA.IP) > 5) then
		if(TESLA.POLL_INTERVAL ~= "0") then
			if (pollTimer ~= nil) then
				C4:KillTimer(pollTimer)
				pollTimer = nil
			end
			pollTimer = C4:AddTimer(TESLA.POLL_INTERVAL, "SECONDS", false)
		end
	end
end
-------------------------------------------
-- // END OF ON PROPERTY CHANGED Functions.
-------------------------------------------

-------------------------------------------------------------------
--Function Name : OnTimerExpired(idTimer)
--Parameters    : idTimer(int)
--Description   : Function called when timer expires
-------------------------------------------------------------------
function OnTimerExpired(idTimer)
	if (idTimer == pollTimer) then
		if (pollTimer ~= nil) then
			C4:KillTimer(pollTimer)
			pollTimer = nil
		end
		TESLA.POLL()
	elseif (idTimer == reconnectTimer) then
		if (reconnectTimer ~= nil) then
			C4:KillTimer(reconnectTimer)
			reconnectTimer = nil
		end
		TESLA.POLL()
	end
end

-------------------------------------------------------------------
--Function Name : OnDriverInit()
--Parameters    : 
--Description   : Function called before properties has initialised
-------------------------------------------------------------------
function OnDriverInit()
    for k,v in pairs(Properties) do
       OnPropertyChanged(k)
    end
	-- Connection Status
	C4:AddVariable("CONNECTION_STATUS", "OFFLINE", "STRING")
	-- Session Vitals
	C4:AddVariable("VEHICLE_CHARGING", "0", "BOOL")
	C4:AddVariable("VEHICLE_CONNECTED", "0", "BOOL")
	C4:AddVariable("SESSION_TIME", "0", "NUMBER")
	C4:AddVariable("GRID_VOLTAGE", "0", "NUMBER")
	C4:AddVariable("GRID_FREQUENCY", "0", "NUMBER")
	C4:AddVariable("VEHICLE_CURRENT", "0", "NUMBER")
	C4:AddVariable("CURRENT_PHASE_1", "0", "NUMBER")
	C4:AddVariable("CURRENT_PHASE_2", "0", "NUMBER")
	C4:AddVariable("CURRENT_PHASE_3", "0", "NUMBER")
	C4:AddVariable("CURRENT_NEUTRAL", "0", "NUMBER")
	C4:AddVariable("VOLTAGE_PHASE_1", "0", "NUMBER")
	C4:AddVariable("VOLTAGE_PHASE_2", "0", "NUMBER")
	C4:AddVariable("VOLTAGE_PHASE_3", "0", "NUMBER")
	C4:AddVariable("RELAY_COIL_VOLTAGE", "0", "NUMBER")
	C4:AddVariable("PCBA_TEMP", "0", "NUMBER")
	C4:AddVariable("HANDLE_TEMP", "0", "NUMBER")
	C4:AddVariable("MCU_TEMP", "0", "NUMBER")
	C4:AddVariable("SESSION_UPTIME", "0", "NUMBER")
	C4:AddVariable("INPUT_THERMOPILE_UV", "0", "NUMBER")
	C4:AddVariable("PROX_V", "0", "NUMBER")
	C4:AddVariable("PILOT_SIGNAL_HIGH_VOLTAGE", "0", "NUMBER")
	C4:AddVariable("PILOT_SIGNAL_LOW_VOLTAGE", "0", "NUMBER")
	C4:AddVariable("DELIVERED_SESSION_ENERGY", "0", "NUMBER")
	C4:AddVariable("CONFIG_STATUS", "0", "NUMBER")
	C4:AddVariable("WALL_CHARGER_STATE", "0", "NUMBER")
	C4:AddVariable("CURRENT_ALERTS", "", "STRING")
	-- Lifetime Stats
	C4:AddVariable("LIFETIME_CONTACTOR_CYCLES", "0", "NUMBER")
	C4:AddVariable("LIFETIME_CONTACTOR_CYCLES_LOADED", "0", "NUMBER")
	C4:AddVariable("LIFETIME_ALERT_COUNT", "0", "NUMBER")
	C4:AddVariable("LIFETIME_THERMAL_FOLDBACKS", "0", "NUMBER")
	C4:AddVariable("LIFETIME_AVERAGE_STARTUP_TEMP", "0", "NUMBER")
	C4:AddVariable("LIFETIME_STARTED_CHARGES", "0", "NUMBER")
	C4:AddVariable("LIFETIME_TOTAL_ENERGY_DELIVERED", "0", "NUMBER")
	C4:AddVariable("LIFETIME_CONNECTOR_CYCLES", "0", "NUMBER")
	C4:AddVariable("LIFETIME_UPTIME", "0", "NUMBER")
	C4:AddVariable("LIFETIME_TOTAL_CHARGING_TIME", "0", "NUMBER")
	-- Wifi Status
	C4:AddVariable("WIFI_SSID", "", "STRING")
	C4:AddVariable("WIFI_SIGNAL_STRENGTH", "0", "NUMBER")
	C4:AddVariable("WIFI_RSSI", "0", "NUMBER")
	C4:AddVariable("WIFI_SNR", "0", "NUMBER")
	C4:AddVariable("WIFI_CONNECTED", "0", "BOOL")
	C4:AddVariable("WIFI_IP", "", "STRING")
	C4:AddVariable("INTERNET_CONNECTED", "0", "BOOL")
	C4:AddVariable("WIFI_MAC", "", "STRING")
	-- Version
	C4:AddVariable("FIRMWARE_VERSION", "", "STRING")
	C4:AddVariable("PART_NUMBER", "", "STRING")
	C4:AddVariable("SERIAL_NUMBER", "", "STRING")
end

-------------------------------------------------------------------
--Function Name : OnDriverLateInit()
--Parameters    : 
--Description   : Function called after properties has initialised
-------------------------------------------------------------------
function OnDriverLateInit()
    C4:AllowExecute(true)
	C4:urlSetTimeout(10)
	C4:UpdateProperty("Driver Name", C4:GetDriverConfigInfo("name"))
	C4:UpdateProperty("Driver Version", C4:GetDriverConfigInfo("version"))
	if (Properties["Poll Interval (Seconds)"] ~= "0") then
		TESLA.POLL_INTERVAL = Properties["Poll Interval (Seconds)"]
		if (pollTimer ~= nil) then
			C4:KillTimer(pollTimer)
			pollTimer = nil
		end
		pollTimer = C4:AddTimer(TESLA.POLL_INTERVAL, "SECONDS", false)
	end
	if (Properties["Device IP"] == '') then
		if (pollTimer ~= nil) then
			C4:KillTimer(pollTimer)
			pollTimer = nil
		end
	end
end

-------------------------------------------------------------------
--Function Name : OnDriverDestroyed()
--Parameters    : 
--Description   : Function called when driver deleted or updated
-------------------------------------------------------------------
function OnDriverDestroyed()
	if (pollTimer ~= nil) then
		C4:KillTimer(pollTimer)
		pollTimer = nil
	end
	if (reconnectTimer ~= nil) then
		C4:KillTimer(reconnectTimer)
		reconnectTimer = nil
	end
	-- Connection Status
	C4:DeleteVariable("CONNECTION_STATUS")
	-- Session Vitals
	C4:DeleteVariable("VEHICLE_CHARGING")
	C4:DeleteVariable("VEHICLE_CONNECTED")
	C4:DeleteVariable("SESSION_TIME")
	C4:DeleteVariable("SESSION_CHARGING_TIME")
	C4:DeleteVariable("GRID_VOLTAGE")
	C4:DeleteVariable("GRID_FREQUENCY")
	C4:DeleteVariable("VEHICLE_CURRENT")
	C4:DeleteVariable("CURRENT_PHASE_1")
	C4:DeleteVariable("CURRENT_PHASE_2")
	C4:DeleteVariable("CURRENT_PHASE_3")
	C4:DeleteVariable("CURRENT_NEUTRAL")
	C4:DeleteVariable("VOLTAGE_PHASE_1")
	C4:DeleteVariable("VOLTAGE_PHASE_2")
	C4:DeleteVariable("VOLTAGE_PHASE_3")
	C4:DeleteVariable("RELAY_COIL_VOLTAGE")
	C4:DeleteVariable("PCBA_TEMP")
	C4:DeleteVariable("HANDLE_TEMP")
	C4:DeleteVariable("MCU_TEMP")
	C4:DeleteVariable("SESSION_UPTIME")
	C4:DeleteVariable("INPUT_THERMOPILE_UV")
	C4:DeleteVariable("PROX_V")
	C4:DeleteVariable("PILOT_SIGNAL_HIGH_VOLTAGE")
	C4:DeleteVariable("PILOT_SIGNAL_LOW_VOLTAGE")
	C4:DeleteVariable("DELIVERED_SESSION_ENERGY")
	C4:DeleteVariable("CONFIG_STATUS")
	C4:DeleteVariable("WALL_CHARGER_STATE")
	C4:DeleteVariable("CURRENT_ALERTS")
	-- Lifetime Stats
	C4:DeleteVariable("LIFETIME_CONTACTOR_CYCLES")
	C4:DeleteVariable("LIFETIME_CONTACTOR_CYCLES_LOADED")
	C4:DeleteVariable("LIFETIME_ALERT_COUNT")
	C4:DeleteVariable("LIFETIME_THERMAL_FOLDBACKS")
	C4:DeleteVariable("LIFETIME_AVERAGE_STARTUP_TEMP")
	C4:DeleteVariable("LIFETIME_STARTED_CHARGES")
	C4:DeleteVariable("LIFETIME_TOTAL_ENERGY_DELIVERED")
	C4:DeleteVariable("LIFETIME_CONNECTOR_CYCLES")
	C4:DeleteVariable("LIFETIME_UPTIME")
	C4:DeleteVariable("LIFETIME_TOTAL_CHARGING_TIME")
	-- Wifi Status
	C4:DeleteVariable("WIFI_SSID")
	C4:DeleteVariable("WIFI_SIGNAL_STRENGTH")
	C4:DeleteVariable("WIFI_RSSI")
	C4:DeleteVariable("WIFI_SNR")
	C4:DeleteVariable("WIFI_CONNECTED")
	C4:DeleteVariable("WIFI_IP")
	C4:DeleteVariable("INTERNET_CONNECTED")
	C4:DeleteVariable("WIFI_MAC")
	-- Version
	C4:DeleteVariable("FIRMWARE_VERSION")
	C4:DeleteVariable("PART_NUMBER")
	C4:DeleteVariable("SERIAL_NUMBER")
end

-------------------------------------------------------------------
--Function Name : Dbg(debugString)
--Parameters    : debugString(string)
--Description   : Function called to output debug
-------------------------------------------------------------------
function Dbg(debugString)
    if (debugMode == 1) then
		print(debugString)
    end
end

----------------------------------------------------------------------------------------------------
--Function Name : FormatSeconds(seconds)
--Parameters    : seconds(string)
--Description   : Function called to format Seconds to years, months, days, hours, minutes, seconds.
----------------------------------------------------------------------------------------------------
function FormatSeconds(seconds)
	local years = math.floor(seconds / 31536000)
	local remainder = seconds % 31536000
	
	local months = math.floor(remainder / 2628288)
	local remainder = remainder % 2628288

	local days = math.floor(remainder / 86400)
	local remainder = remainder % 86400
	
	local hours = math.floor(remainder / 3600)
	local remainder = remainder % 3600
	
	local minutes = math.floor(remainder / 60)
	
	local seconds = remainder % 60
	
	return years, months, days, hours, minutes, seconds
end

---------------------------------------------------------------
--Function Name : BuildTime(UptimeSeconds)
--Parameters    : UptimeSeconds(string)
--Description   : Function called to generate a formatted time
---------------------------------------------------------------
function BuildTime(UptimeSeconds)
    if UptimeSeconds <= 0 then return "" end
	local years, months, days, hours, minutes, seconds = FormatSeconds(UptimeSeconds)
	if UptimeSeconds >= 31536000 then
		local outPattern = "%dy %dm %dd %dh %dm %ds"
		return string.format(outPattern, years, months, days, hours, minutes, seconds)
	elseif UptimeSeconds >= 2628288 then
		local outPattern = "%dm %dd %dh %dm %ds"
		return string.format(outPattern, months, days, hours, minutes, seconds)
	elseif UptimeSeconds >= 86400 then
		local outPattern = "%dd %dh %dm %ds"
		return string.format(outPattern, days, hours, minutes, seconds)
	elseif UptimeSeconds >= 3600 then
		local outPattern = "%dh %dm %ds"
		return string.format(outPattern, hours, minutes, seconds)
	elseif UptimeSeconds >= 60 then
		local outPattern = "%dm %ds"
		return string.format(outPattern, minutes, seconds)
	else -- seconds
		local outPattern = "%ds"
		return string.format(outPattern, seconds)
	end
end

-- Driver loaded.
print("Driver Loaded... " .. os.date())