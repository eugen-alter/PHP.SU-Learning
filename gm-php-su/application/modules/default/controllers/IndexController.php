<?
class IndexController extends GM_Controller_Base
{
    function init()
    {
        parent::init();
    }

    function indexAction()
    {
        
    }

    function testAction()
    {
        $this->view->sSQL=$this->_getParam('sql');
        try
        {
            $this->view->rgQuery   = $this->_rDb->getAdapter()->query($this->_getParam('sql'))->fetchAll();
        }
        catch(Exception $e)
        {
            $this->view->sError     = $e->getMessage();
        }
    }
}
