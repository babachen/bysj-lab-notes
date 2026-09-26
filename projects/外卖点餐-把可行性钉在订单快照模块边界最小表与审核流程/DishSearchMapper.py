# 对照草稿：示意查询，不保证可直接运行
class DishSearchMapper:
    def search(self, keyword, merchant_id=None, page=1, size=10):
        body = {
            "query": {"bool": {"must": [
                {"match": {"name": keyword}},
                {"term": {"sale_status": "ON_SALE"}}
            ]},
            "from": (page - 1) * size,
            "size": size
        }
        if merchant_id:
            body["query"]["bool"]["filter"] = [
                {"term": {"merchant_id": merchant_id}}
            ]
        return self.client.search(index="dish_read", body=body)
