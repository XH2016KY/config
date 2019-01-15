package com.oks.web

import org.springframework.stereotype.Controller
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestMethod
import com.oks.pojo.Product
import org.springframework.web.bind.annotation.ResponseBody
import org.apache.logging.log4j.Logger
import org.apache.logging.log4j.LogManager
import java.util.concurrent.TimeUnit
import java.util.concurrent.ThreadPoolExecutor
import java.util.concurrent.LinkedBlockingDeque
import org.springframework.web.context.request.async.DeferredResult
import java.util.Date
import com.oks.service.IProductService
import java.util.concurrent.locks.Lock
import java.util.concurrent.locks.ReentrantLock

@Controller
class ProductController {

	/** 日志 */
	static final Logger log = LogManager.getLogger(UserController)
	/** 线程池 */
	val pool = new ThreadPoolExecutor(3, 5, 60, TimeUnit.SECONDS, new LinkedBlockingDeque(200))
	/** 重入锁 */
	static Lock lock = new ReentrantLock

	@Autowired
	IProductService productService

	@RequestMapping(value="sell", method=RequestMethod.POST, produces="application/json;charset=utf-8")
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

	@RequestMapping(value="sellasy", method=RequestMethod.POST, produces="application/json;charset=utf-8")
	@ResponseBody
	def asy(Product product) {
		var start = new Date().time
		log.info("异步处理开始->{}", start)
		val d = new DeferredResult<ServerRespose<Object>>(5*2000L,ServerRespose::FailOfError(500,"超时了"))
		val Runnable r = [|

			lock.lock
			try {
				var a = productService.selectCount - product.quatity
				log.info("库存->{}", a)
				if (a < 0) {
					d.result = ServerRespose::FailOfError(500)
					log.info("状态->库存不够")
				} else {
					productService.updateQuatity(a)
					d.result = ServerRespose::SuccessOfOK(200)
					log.info("状态->成功购买")
				}

			} finally {
				lock.unlock
			}
		]
		pool.execute(r)
		log.info("异步处理用时->{}", new Date().time - start)
		d

	}
}
