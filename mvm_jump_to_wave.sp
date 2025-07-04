#pragma semicolon 1
#include <dbi>
#include <keyvalues>
#include <sdktools>
#include <sourcemod>
#include <tf2>

public Plugin myinfo =
{
	name = "MvM Jump to Wave",
	description = "Jump to wave with currency",
	author = "Revan",
	version = "0.0.1",
	url = "https://github.com/cooolbros/mvm_jump_to_wave"
};

public void OnPluginStart()
{
	RegConsoleCmd("wave", Command_Wave, "Jump to wave with currency");
}

public Action Command_Wave(int client, int args)
{
	if (client == 0)
	{
		return Plugin_Handled;
	}

	if (args != 1)
	{
		return Plugin_Handled;
	}

	char tf_mvm_popfile_output[PLATFORM_MAX_PATH];
	ServerCommandEx(tf_mvm_popfile_output, sizeof(tf_mvm_popfile_output), "tf_mvm_popfile");
	ReplaceString(tf_mvm_popfile_output, sizeof(tf_mvm_popfile_output), "Current popfile is: ", "", false);
	ReplaceString(tf_mvm_popfile_output, sizeof(tf_mvm_popfile_output), "\n", "", false);

	char arg[PLATFORM_MAX_PATH];
	GetCmdArg(1, arg, sizeof(arg));
	int wave = StringToInt(arg);

	ServerCommand("tf_mvm_jump_to_wave %d", wave);

	KeyValues kv = new KeyValues("WaveSchedule");
	if (!kv.ImportFromFile(tf_mvm_popfile_output))
	{
		ReplyToCommand(client, "File Error: %s", tf_mvm_popfile_output);
		return Plugin_Handled;
	}

	if (!kv.GotoFirstSubKey(false))
	{
		ReplyToCommand(client, "KeyValues Error: %s", tf_mvm_popfile_output);
		return Plugin_Handled;
	}

	int startingCurrency;
	int total;
	int i;

	do
	{
		char key[PLATFORM_MAX_PATH];
		kv.GetSectionName(key, sizeof(key));

		if (StrEqual(key, "StartingCurrency", false))
		{
			startingCurrency = kv.GetNum(NULL_STRING);
			PrintToChatAll("Starting Currency: %d", startingCurrency);
		}
		else if (StrEqual(key, "Wave", false) && kv.GotoFirstSubKey(false) && i < wave - 1)
		{
			int currency = 0;

			do
			{
				char key[PLATFORM_MAX_PATH];
				kv.GetSectionName(key, sizeof(key));

				if (StrEqual(key, "WaveSpawn", false))
				{
					int totalCurrency = kv.GetNum("TotalCurrency");
					if (totalCurrency > 0)
					{
						currency += totalCurrency;
					}
				}
			}
			while (kv.GotoNextKey(false));

			PrintToChatAll("Wave %d: %d", i + 1, currency);

			currency += 100;	// A+
			total += currency;

			i++;
			kv.GoBack();
		}
	}
	while (kv.GotoNextKey(false));

	CreateTimer(0.1, SetCurrency, startingCurrency + total);
	delete kv;
	return Plugin_Handled;
}

void SetCurrency(Handle timer, int currency)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == view_as<int>(TFTeam_Red))
		{
			SetEntProp(i, Prop_Send, "m_nCurrency", currency);
		}
	}
}
