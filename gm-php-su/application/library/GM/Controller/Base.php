<?php
class GM_Controller_Base extends Zend_Controller_Action
{
    public function init()
    {

    }
    
    public function postDispatch()
    {
        $this->getResponse()->setHeader('Content-Type', 'text/html; charset=UTF-8', true);
        $this->getResponse()->setHeader('Pragma', 'no-cache', true);
    }
}

?>
