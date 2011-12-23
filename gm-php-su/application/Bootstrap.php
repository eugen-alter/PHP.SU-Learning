<?php
class Bootstrap extends Zend_Application_Bootstrap_Bootstrap
{
    protected function _initRequest()
    {
        date_default_timezone_set('Europe/Moscow');

        Zend_Session::start();

        //Add our 'GM' application(model) namespace:
        $rLoader = Zend_Loader_Autoloader::getInstance();
        $rLoader->registerNamespace('GM_');

        // FRONT CONTROLLER - Get the front controller.
        $frontController = Zend_Controller_Front::getInstance();

        // CONTROLLER DIRECTORY SETUP - Point the front controller to your action
        $frontController->addModuleDirectory( APPLICATION_PATH."/modules");
        
        // APPLICATION ENVIRONMENT - Set the current environment
        $frontController->setParam('env', APPLICATION_ENV);


        // CONFIGURATION - Setup the configuration object
        $configuration = new Zend_Config_Ini(APPLICATION_PATH . '/config/gm.ini', APPLICATION_ENV);

        //install cache
        $frontendOptions = array(
            'automatic_serialization' => true,
            'caching' => true,
            );

        $backendOptions  = array( 'cache_dir' => $configuration->local_dir . '/cache/');

        if(false)
        {
            $backend = 'Memcached';
        }
        else
        {
            $backend = 'File';
        }

        $cache = Zend_Cache::factory('Core', $backend, $frontendOptions, $backendOptions);

        // DATABASE ADAPTER - Setup the database adapter

        $database = $configuration->database->toArray();
        $database['params']['driver_options'] = array(PDO::MYSQL_ATTR_INIT_COMMAND => 'SET NAMES \'UTF8\'');

        $dbAdapter = Zend_Db::factory( $database['adapter'], $database['params']);

        $profiler = new Zend_Db_Profiler_Firebug('All DB Queries');
        $profiler->setEnabled(true);
        $dbAdapter->setProfiler($profiler);

        // DATABASE TABLE SETUP - Setup the Database Table Adapter
        Zend_Db_Table_Abstract::setDefaultAdapter($dbAdapter);
        Zend_Db_Table_Abstract::setDefaultMetadataCache($cache);


        // REGISTRY - setup the application registry
        $registry = Zend_Registry::getInstance();
        $registry->configuration = $configuration;
        $registry->dbAdapter     = $dbAdapter;
        /*
        //DB SESSION SETTINGS: in case of multiple servers
        Zend_Session::setSaveHandler(new Zend_Session_SaveHandler_DbTable($configuration->db_sessions));
        Zend_Session::start();
        */

        $frontController->setRequest( new GM_Controller_Request_Http());

        //ROUTES: each for default (options), personal and admin
        $router = $frontController->getRouter();
        $compat = new Zend_Controller_Router_Route_Module(array(),
                                                          $frontController->getDispatcher(),
                                                          $frontController->getRequest());
        $router->addRoute('default', $compat);
        $router->addRoute('personal', new Zend_Controller_Router_Route('personal/:uid/:controller/:action/:parameter',
                array( 'module'=>'personal', 'uid' => 0, 'controller' => 'index', 'action' => 'index', 'parameter' => '1')
            ));
        $router->addRoute('admin', new Zend_Controller_Router_Route('admin/:controller/:action/:parameter',
                array( 'module'=>'admin', 'controller' => 'index', 'action' => 'index', 'parameter' => '1')
            ));


        // LAYOUT SETUP - Setup the layout component
        Zend_Layout::startMvc(APPLICATION_PATH . '/common/layouts');

        // VIEW SETUP - Initialize properties of the view object
        $view = new GM_View();

        Zend_Layout::getMvcInstance()->setView( $view);

        $viewRenderer =
            Zend_Controller_Action_HelperBroker::getStaticHelper('viewRenderer');
        $viewRenderer->setView( $view);

        $registry->cache = $cache;


        // CLEANUP (?)

        unset($frontController, $view, $configuration, $dbAdapter, $registry, $cache);

    }
}
?>