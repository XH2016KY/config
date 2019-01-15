import org.springframework.stereotype.Controller
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestMethod
import com.oks.pojo.Product
import org.springframework.web.bind.annotation.ResponseBody
import org.apache.logging.log4j.Logger
import org.apache.logging.log4j.LogManager
import org.springframework.web.context.request.async.DeferredResult
import java.util.Date
import com.oks.service.IProductService
import com.oks.utils.ThreadPoolUtil
import java.util.concurrent.atomic.AtomicReference

@Controller
class ProductAtomicController {

	/** 日志 */
	static final Logger log = LogManager.getLogger(UserController)
	
	/** 线程池 */
	val pool = ThreadPoolUtil::createPool(4,8,60L)
	
	@Autowired
	IProductService productService

	@RequestMapping(value="Atomicsell", method=RequestMethod.POST, produces="application/json;charset=utf-8")
	@ResponseBody
	def add(Product product) {
		var start = new Date().time
		log.info("同步处理开始->{}", start)
		var a = productService.selectCount - product.quatity
		if (a < 0) {
			ServerRespose::FailOfError(500)
			log.info("同步处理用时->{}", new Date().time - start)
		} else {
			productService.updateQuatity(a)
			ServerRespose::SuccessOfOK(200)
			log.info("同步处理用时->{}", new Date().time - start)
		}
	}

	@RequestMapping(value="Atomicsellasy", method=RequestMethod.POST, produces="application/json;charset=utf-8")
	@ResponseBody
	def asy(Product product) {
		var start = new Date().time
		log.info("异步处理开始->{}", start)
		val d = new DeferredResult<ServerRespose<Object>>(5*2000L,ServerRespose::FailOfError(500,"超时了"))
		val Runnable r = [|
                /** Atomic */
	        val AtomicReference<Integer> count = new AtomicReference(0)
			count.compareAndSet(0,productService.selectCount)
			try {
				var a = productService.selectCount - product.quatity
				count.compareAndSet(productService.selectCount,a)
				var sta = new Date().time
				log.info("副线程开始处理:{}",sta)
				log.info("库存->{}", a)
				if (a < 0) {
					d.result = ServerRespose::FailOfError(500)
					log.info("状态->库存不够")
					log.info("副线程处理完毕:{}",new Date().time-sta)
				} else {
					productService.updateQuatity(count.get)
					d.result = ServerRespose::SuccessOfOK(200)
					log.info("状态->成功购买")
					log.info("副线程处理完毕:{}",new Date().time-sta)
				}	
			} catch (Exception exception) {
				log.info("异常:{}",exception.message)
			} finally {
				
			}
		]
		pool.execute(r)
		log.info("异步处理用时->{}", new Date().time - start)
		d

	}
}

