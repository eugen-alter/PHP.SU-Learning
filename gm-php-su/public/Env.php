<?php
function getSection($rgConfig, $bIsBackend=false)
{
    $sPart=$bIsBackend?'backend':'frontend';
    if(!array_key_exists($sPart, $rgConfig))
    {
        return null;
    }
    $rgConfig   = $rgConfig[$sPart];
    if(!array_key_exists(php_uname("n"), $rgConfig))
    {
        return null;
    }
    $rgConfig   = $rgConfig[php_uname("n")];
    if(!is_array($rgConfig))
    {
        return $rgConfig;
    }
    else
    {
        if(array_key_exists(dirname(realpath(__FILE__)), $rgConfig))
        {
            return $rgConfig[dirname(realpath(__FILE__))];
        }
        elseif(array_key_exists(fileinode(dirname(realpath(__FILE__))), $rgConfig))
        {
            return $rgConfig[fileinode(dirname(realpath(__FILE__)))];
        }
        else
        {
            return null;
        }
    }
}

// Define application environment by:
// * backend/frontend variable: is set in corresponding backend bootstrap
// * `uname -n` variable (it is referring to local machine's name)
// * file inode (only for *nix machines) or full path (for Win machines), the priority is given to full path
// This is useful when, for example, we want to set up multiple instances on one local machine.
// Note: it is possible to use `uname -n` key directly as a config entry (without file inode or full path keys inside).
// However, if you're using string key for `uname -n` you can not use different config options for one machine.

$rgEnv = array(

	'frontend'  => array(

		'toril' => array(433426 => 'EuGen',),
		'R-SYSTEM' => 'BaltazoR',
		'Q' => 'sKaa',
		'UPOP' => 'DlTA',
		'ALEKCHI' => 'Alek',
		'user-a30880e950' => 'etoYA',
		'ubuntu-laptop' => 'DeepVarvar',
        	'ubuntu-panoptik' => array(16911226 => 'Panoptik',),

		),

	'backend' => array(

		'toril' => array(433426 => 'EuGen',),
		'R-SYSTEM' => 'BaltazoR',
		'Q' => 'sKaa',
		'UPOP' => 'DlTA',
		'ALEKCHI' => 'Alek',
		'user-a30880e950' => 'etoYA',
		'ubuntu-laptop' => 'DeepVarvar',
		'ubuntu-panoptik' => array(16911226 => 'Panoptik',),

		)


);

$sSection=getSection($rgEnv, isset($bIsBackend));

if(empty($sSection))
{
    header('Location: maintenance.html');
    exit();
}
define('APPLICATION_ENV', $sSection);
